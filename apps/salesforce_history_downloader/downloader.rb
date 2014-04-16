module GoodData::Bricks
  class SalesForceHistoryDownloader < BaseDownloader

    # TZ = ActiveSupport::TimeZone.new('UTC')
    # DATE_FROM = DateTime.now.advance(:days => -29).in_time_zone(TZ).iso8601
    # DATE_TO = DateTime.now.in_time_zone(TZ).iso8601

    # objects = ["Account", "Opportunity", "User", "Contact", "Lead", "Case", "Contract", "Product2", "Task", "Event"]

    def download
      client = @params["salesforce_client"]
      bulk_client = @params["salesforce_bulk_client"]
      objects = @params["salesforce_objects"]
      objects.each do |mod|
        name = "#{mod}-#{DateTime.now.to_i.to_s}.csv"

        main_data = download_main_dataset(client, bulk_client, mod)

        CSV.open(name, 'w', :force_quotes => true) do |csv|
          my_fields = fields(client, mod)
          csv << my_fields
          main_data.map do |u|
            csv << u.values_at(*my_fields)
          end
        end

      end
      []
    end

    private

    def download_main_dataset(client, bulk_client, mod)
      fields = fields(client, mod)
      q = construct_query(mod, fields)
      res = bulk_client.query(mod, q)
      data = res.result.records
    end

    def fields(client, obj)
      description = client.describe(obj)
      description.fields.map {|f| f.name}
    end

    def construct_query(obj, fields)
      "SELECT #{fields.join(', ')} FROM #{obj}"
    end

  end
end