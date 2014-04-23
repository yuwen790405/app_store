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
      instance = bulk_client.instance_eval('@connection').parse_instance

      # TODO would be nice to take from describe call
      # 1.9.3-p484 :008 > h["urls"]["uiDetailTemplate"]
      # => "https://na12.salesforce.com/{ID}"
      downloaded_info[:salesforce_server] = "https://#{instance}.salesforce.com/"

      # create the directory if it doesn't exist
      Dir.mkdir(DIRNAME) if ! File.directory?(DIRNAME)

      objects.each do |obj|
        name = "tmp/#{obj}-#{DateTime.now.to_i.to_s}.csv"

        main_data = download_main_dataset(client, bulk_client, obj)

        CSV.open(name, 'w', :force_quotes => true) do |csv|
          # get the list of fields and write them as a header
          obj_fields = fields(client, obj)
          csv << obj_fields
          downloaded_info[:objects][obj] = {
            :fields => obj_fields,
            :filename => File.absolute_path(name),
          }

          # write the stuff to the csv
          main_data.map do |u|
            # get rid of the weird stuff coming from the api
            csv_line = u.values_at(*obj_fields).map do |m|
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
      return downloaded_info
    end

    private

    def download_main_dataset(client, bulk_client, obj)
      fields = fields(client, obj)
      q = construct_query(obj, fields)
      logger = @params["GDC_LOGGER"]
      logger.info "Executing soql: #{q}" if logger

      begin
        # try it with the bulk
        res = bulk_client.query(obj, q)
        if res["state"] == ["Failed"]
          raise "Something went wrong: #{res}"
        end

        data =  res["batches"].reduce([]) do |r, b|
          r + b["response"]
        end
      rescue
        logger.warn "Batch download failed. Now downloading through REST api instead" if logger
        # if not, try the normal api
        data = client.query(q)
      end
    end

    # get the list of fields for an object
    def fields(client, obj)
      description = client.describe(obj)
      # return the names of the fields
      # TODO: return the types as well
      description.fields.map {|f| f.name}
    end

    def construct_query(obj, fields)
      "SELECT #{fields.join(', ')} FROM #{obj}"
    end

  end
end
