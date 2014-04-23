require 'rubygems'
require 'sequel'
require 'jdbc/dss'

module GoodData::Bricks
  class DssExecutor
    def initialize(params)
      if (!params["dss_GDC_USERNAME"]) || (!params["dss_GDC_PASSWORD"])
        # use the standard ones
        params["dss_GDC_USERNAME"] = params["GDC_USERNAME"]
        params["dss_GDC_PASSWORD"] = params["GDC_PASSWORD"]
      end
      @params = params
      @logger = @params["GDC_LOGGER"]


      Jdbc::DSS.load_driver
      Java.com.gooddata.dss.jdbc.driver.DssDriver
    end

    # expecting hash:
    # table name ->
    #   :fields -> list of columns
    def create_tables(table_hash)
      # create the tables one by one
      table_hash.each do |table, table_meta|
        sql = get_create_sql(table, table_meta[:fields])
        execute(sql)
      end
    end

    # expecting hash:
    # table name ->
    #   :fields -> list of columns
    #   :filename -> name of the csv file
    def load_data(table_hash)
      # load the data
      table_hash.each do |table, table_meta|
        sql = get_upload_sql(table, table_meta[:fields], table_meta[:filename])
        execute(sql)
      end
    end

    LOAD_INFO_TABLE_NAME = 'meta_loads'

    def save_download_info(downloaded_info)
      # create the load table if it doesn't exist yet
      create_sql = get_create_sql(LOAD_INFO_TABLE_NAME, ['Salesforce_Server'])
      execute(create_sql)

      # insert it there
      insert_sql = get_insert_sql(sql_table_name(LOAD_INFO_TABLE_NAME), {"Salesforce_Server" => downloaded_info[:salesforce_server]})
      execute(insert_sql)
    end

    DIRNAME = "tmp"

    # extracts data to be filled in to datasets,
    # writes them to a csv file
    def extract_data(datasets)
      # create the directory if it doesn't exist
      Dir.mkdir(DIRNAME) if ! File.directory?(DIRNAME)

      # extract load info and put it my own params
      @params[:salesforce_downloaded_info] = get_load_info

      # extract each dataset from vertica
      datasets.each do |dataset, ds_structure|
        columns = get_columns(ds_structure)
        columns_sql = columns[:sql]
        columns_gd = columns[:gd]


        # get the sql
        sql = get_extract_sql(
          ds_structure["source_table"],
          columns_sql
        )
        name = "tmp/#{dataset}-#{DateTime.now.to_i.to_s}.csv"

        # open a file to write select results to it
        CSV.open(name, 'w', :force_quotes => true) do |csv|
          # write the header there
          csv << columns_gd

          # execute the select and write row by row
          execute_select(sql) do |row|
            row_array = columns_gd.map {|col| row[col.downcase.to_sym]}
            csv << row_array
          end
        end
      end
    end

    def table_has_column(table, column)
      count = nil
      execute_select("SELECT COUNT(column_name) FROM columns WHERE table_name = '#{table}' and column_name = '#{column}'") do |row|

        count = row[:count]
      end
      return count > 0
    end

    # get columns to be part of the SELECT query
    def get_columns(ds_structure)
      columns_sql = []
      columns_gd = []
      # go through all the fields of the dataset
      ds_structure["fields"].each do |f|
        # push the gd identifier to list of csv columns
        csv_column_name = f["gooddata_identifier"]
        columns_gd.push(csv_column_name)

        # if it's optional and it's not in the table, return empty
        if f["optional"]
          source_column = f["source_column"]
          if ! source_column
            raise "source column must be given for optional: #{f}"
          end

          if ! table_has_column(ds_structure["source_table"], source_column)
            columns_sql.push("'' AS #{csv_column_name}")
            next
          end
        end

        # if column name given, push it there directly
        if f["source_column"]
          columns_sql.push("#{f['source_column']} AS #{csv_column_name}")
          next
        end

        # same if source_column_expression given
        if f["source_column_expression"]
          columns_sql.push("#{f['source_column_expression']} AS #{csv_column_name}")
          next
        end

        # if there's something to be evaluated, do it
        if f["source_column_concat"]
          # through the stuff to be concated
          concat_strings = f["source_column_concat"].map do |c|
            # if it's a symbol get it from the load params
            if c[0] == ":"
              "'#{@params[:salesforce_downloaded_info][c[1..-1].to_sym]}'"
            else
              # take the value as it is, including apostrophes if any
              c
            end
          end
          columns_sql.push("(#{concat_strings.join(' || ')}) AS #{csv_column_name}")
          next
        end
        raise "source_column or source_column_concat must be given for #{f}"
      end
      return {
        :sql => columns_sql,
        :gd => columns_gd
      }
    end

    def get_load_info
      # get information from the meta table latest row
      # return it in form column name -> value
      select_sql = get_extract_load_info_sql
      info = {}
      execute_select(select_sql) do |row|
        info.merge!(row)
      end
      return info
    end

    # connect and pass execution to a block
    def connect
      Sequel.connect @params["dss_jdbc_url"],
        :username => @params["dss_GDC_USERNAME"],
        :password => @params["dss_GDC_PASSWORD"] do |connection|
          yield(connection)
      end
    end

    # executes sql (select), for each row, passes execution to block
    def execute_select(sql)
      connect do |connection|
        @logger.info("Executing sql: #{sql}") if @logger
        return connection.fetch(sql) do |row|
          yield(row) if block_given?
        end
      end
    end

    # execute sql, return nothing
    def execute(sql_strings)
      if ! sql_strings.kind_of?(Array)
        sql_strings = [sql_strings]
      end
      connect do |connection|
          sql_strings.each do |sql|
            @logger.info("Executing sql: #{sql}") if @logger
            connection.run(sql)
          end
      end
    end

    private

    def sql_table_name(obj)
      return "dss_#{obj}"
    end
    def obj_name(sql_table)
      return sql_table[4..-1]
    end

    ID_COLUMN = {"_oid" => "IDENTITY PRIMARY KEY"}

    HISTORIZATION_COLUMNS = [
      {"_LOAD_ID" => "VARCHAR(255)"},
      {"_INSERTED_AT" => "TIMESTAMP NOT NULL DEFAULT now()"},
      {"_IS_DELETED" => "boolean NOT NULL DEFAULT FALSE"},
    ]

    def get_create_sql(table, fields)
      # TODO types
      fields_string = fields.map{|f| "#{f} VARCHAR(255)"}.join(", ")
      hist_columns = HISTORIZATION_COLUMNS.map {|col| "#{col.keys[0]} #{col.values[0]}"}.join(", ")
      return "CREATE TABLE IF NOT EXISTS #{sql_table_name(table)}
      (#{ID_COLUMN.keys[0]} #{ID_COLUMN.values[0]}, #{fields_string}, #{hist_columns})"
    end

    # filename is absolute
    def get_upload_sql(table, fields, filename)
      # TODO fill load id
      return "COPY #{sql_table_name(table)} (#{fields.join(',')})
      FROM LOCAL '#{filename}' WITH PARSER GdcCsvParser()
       SKIP 1
      EXCEPTIONS '#{filename}.except.log'
      REJECTED DATA '#{filename}.reject.log' "
    end

    def get_extract_sql(table, columns)
      # TODO last snapshot
      return "SELECT #{columns.join(',')} FROM #{table} WHERE _INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM #{table})"
    end

    def get_extract_load_info_sql
      table_name = sql_table_name(LOAD_INFO_TABLE_NAME)
      return "SELECT * FROM #{table_name} WHERE _INSERTED_AT = (SELECT MAX(_INSERTED_AT) FROM #{table_name})"
    end

    def get_insert_sql(table, column_values)
      columns = column_values.keys
      values = column_values.values_at(*columns)
      values_string = values.map {|e| "'#{e}'"}.join(',')

      return "INSERT INTO #{table} (#{columns.join(',')}) VALUES (#{values_string})"
    end
  end
end