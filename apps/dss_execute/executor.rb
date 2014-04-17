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

      Jdbc::DSS.load_driver
      Java.com.gooddata.dss.jdbc.driver.DssDriver
    end

    # expecting hash:
    # table name ->
    #   :columns -> list of columns
    def create_tables(table_hash)
      # create the tables one by one
      table_hash.each do |table, table_meta|
        sql = get_create_sql(table, table_meta[:columns])
        execute(sql)
      end
    end

    # expecting hash:
    # table name ->
    #   :columns -> list of columns
    #   :filename -> name of the csv file
    def load_data(table_hash)
      # load the data
      table_hash.each do |table, table_meta|
        sql = get_upload_sql(table, table_meta[:columns], table_meta[:filename])
        execute(sql)
      end
    end

    def execute(sql_strings)
      if ! sql_strings.kind_of?(Array)
        sql_strings = [sql_strings]
      end
      logger = @params["GDC_LOGGER"]
      Sequel.connect @params["dss_jdbc_url"],
        :username => @params["dss_GDC_USERNAME"],
        :password => @params["dss_GDC_PASSWORD"] do |conn|
          sql_strings.each do |sql|
            logger.info("Executing sql: #{sql}")
            conn.run(sql)
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

    def get_create_sql(table, fields)
      # TODO types
      fields_string = fields.map{|f| "#{f} VARCHAR(255)"}.join(", ")
      return "CREATE TABLE IF NOT EXISTS #{sql_table_name(table)} (#{fields_string})"
    end

    # filename is absolute
    def get_upload_sql(table, fields, filename)

      return "COPY #{sql_table_name(table)} (#{fields.join(',')})
      FROM LOCAL '#{filename}' WITH PARSER GdcCsvParser()
       SKIP 1
      EXCEPTIONS '#{filename}.except.log'
      REJECTED DATA '#{filename}.reject.log' "
    end
  end
end