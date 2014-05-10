module GoodData::Bricks
  class SalesForceHistoryDownloader < BaseDownloader

    # TZ = ActiveSupport::TimeZone.new('UTC')
    # DATE_FROM = DateTime.now.advance(:days => -29).in_time_zone(TZ).iso8601
    # DATE_TO = DateTime.now.in_time_zone(TZ).iso8601

    # objects = ["Account", "Opportunity", "User", "Contact", "Lead", "Case", "Contract", "Product2", "Task", "Event"]
    DIRNAME = "tmp"

    # returns a hash objects -> what fields have been downloaded
    def download
      downloaded_info = {:objects => {}}
      client = @params["salesforce_client"]
      bulk_client = @params["salesforce_bulk_client"]
      objects = @params["salesforce_objects"]

      # save the information about download - sfdc server
      instance = bulk_client.instance_url

      # TODO would be nice to take from describe call
      # 1.9.3-p484 :008 > h["urls"]["uiDetailTemplate"]
      # => "https://na12.salesforce.com/{ID}"
      downloaded_info[:salesforce_server] = instance

      # create the directory if it doesn't exist
      Dir.mkdir(DIRNAME) if ! File.directory?(DIRNAME)

      objects.each do |obj|
        name = "tmp/#{obj}-#{DateTime.now.to_i.to_s}.csv"

        obj_fields = get_fields(client, obj)

        main_data = download_main_dataset(client, bulk_client, obj, obj_fields)

        # if it's already in files, just write downloaded_info
        if main_data[:in_files]
          downloaded_info[:objects][obj] = {
            :fields => obj_fields,
            :filenames => main_data[:filenames].map {|f| File.absolute_path(f)},
          }
        else
          # otherwise write it to csv
          CSV.open(name, 'w', :force_quotes => true) do |csv|
            # get the list of fields and write them as a header
            csv << obj_fields.map {|f| f[:name]}
            downloaded_info[:objects][obj] = {
              :fields => obj_fields,
              :filenames => [File.absolute_path(name)],
            }

            # write the stuff to the csv
            main_data[:data].map do |row_hash|
              # get rid of the weird stuff coming from the api
              csv_line = row_hash.values_at(*obj_fields.map {|f| f[:name]}).map do |m|
                if m.kind_of?(Array)
                  m[0] == {"xsi:nil"=>"true"} ? nil : m[0]
                else
                  m
                end
              end
              csv << csv_line
            end
          end
        end

      end
      return downloaded_info
    end

    private

    def download_main_dataset(client, bulk_client, obj, fields)
      q = construct_query(obj, fields)
      logger = @params["GDC_LOGGER"]
      logger.info "Executing soql: #{q}" if logger

      begin
        # try it with the bulk

        # start the machinery
        job = bulk_client.start_query(obj, q)
        filenames = nil

        loop do
          # check the status
          status = job.check_job_status
          # if finished get the result and we're done
          if status["finished"]
            # get the results
            filenames = job.get_job_results({:directory_path => DIRNAME})

            break
          end
          sleep(10)
        end

        return {
          :in_files => true,
          :filenames => filenames
        }
      rescue => e
        require 'pry'; binding.pry
        logger.warn "Batch download failed. Now downloading through REST api instead" if logger
        # if not, try the normal api
        data = client.query(q)
        return {
          :in_files => false,
          :data => data
        }
      end
    end

    # get the list of fields for an object
    def get_fields(client, obj)
      description = client.describe(obj)
      # return the names of the fields
      description.fields.map {|f| {:name => f.name, :type => f.type}}
    end

    def construct_query(obj, fields)
      "SELECT #{fields.map {|f| f[:name]}.join(', ')} FROM #{obj}"
    end

  end
end
