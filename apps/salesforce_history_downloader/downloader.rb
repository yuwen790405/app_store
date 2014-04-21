module GoodData::Bricks
  class SalesForceHistoryDownloader < BaseDownloader

    # TZ = ActiveSupport::TimeZone.new('UTC')
    # DATE_FROM = DateTime.now.advance(:days => -29).in_time_zone(TZ).iso8601
    # DATE_TO = DateTime.now.in_time_zone(TZ).iso8601

    # objects = ["Account", "Opportunity", "User", "Contact", "Lead", "Case", "Contract", "Product2", "Task", "Event"]

    # returns a hash object -> what fields have been downloaded
    def download
      downloaded_fields = {}
      client = @params["salesforce_client"]
      bulk_client = @params["salesforce_bulk_client"]
      objects = @params["salesforce_objects"]
      objects.each do |obj|
        name = "tmp/#{obj}-#{DateTime.now.to_i.to_s}.csv"

        main_data = download_main_dataset(client, bulk_client, obj)

        CSV.open(name, 'w', :force_quotes => true) do |csv|
          # get the list of fields and write them as a header
          obj_fields = fields(client, obj)
          csv << obj_fields
          downloaded_fields[obj] = {
            :columns => obj_fields,
            :filename => File.absolute_path(name),
          }

          # write the stuff to the csv
          main_data.map do |u|
            # get rid of the weird stuff coming from the api
            csv << u.values_at(*obj_fields).map {|m| m[0] == {"xsi:nil"=>"true"} ? nil : m[0]}
          end
        end

      end
      return downloaded_fields
    end

    private

    def download_main_dataset(client, bulk_client, obj)
      fields = fields(client, obj)
      q = construct_query(obj, fields)
      res = bulk_client.query(obj, q)
      data =  res["batches"].reduce([]) do |r, b|
        #TODO handle errors:
=begin
 {"xmlns"=>"http://www.force.com/2009/06/asyncapi/dataload",
 "id"=>["751U0000001cdgCIAQ"],
 "jobId"=>["750U000000187p2IAA"],
 "state"=>["Failed"],
 "stateMessage"=>
  ["InvalidBatch : Failed to process query: INVALID_FIELD:  LastActivityDate, Jigsaw, JigsawCompanyId, AccountSource, SicDesc, CustomerPriority__c                                            ^ ERROR at Row:1:Column:487 No such column 'AccountSource' on entity 'Account'. If you are attempting to use a custom field, be sure to append the '__c' after the custom field name. Please reference your WSDL or the describe call for the appropriate names."],
 "createdDate"=>["2014-04-21T21:40:28.000Z"],
 "systemModstamp"=>["2014-04-21T21:40:28.000Z"],
 "numberRecordsProcessed"=>["0"],
 "numberRecordsFailed"=>["0"],
 "totalProcessingTime"=>["0"],
 "apiActiveProcessingTime"=>["0"],
 "apexProcessingTime"=>["0"]}
=end
        r + b["response"]
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
