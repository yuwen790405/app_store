module GoodData::Bricks
  class SalesForceIncrementalDownloader < BaseDownloader

    TZ = ActiveSupport::TimeZone.new('UTC')
    DATE_FROM = DateTime.now.advance(:days => -29).in_time_zone(TZ).iso8601
    DATE_TO = DateTime.now.in_time_zone(TZ).iso8601

    # MODULES = ["Account", "Opportunity", "User", "Contact", "Lead", "Case", "Contract", "Product2", "Task", "Event"]
    MODULES = ["User"]

    def download
      client = @params[:salesforce_client]
      modules = @params[:salesforce_modules] || MODULES

      metadata = modules.reduce([]) do |memo, mod|

        md_name = "salesforce_incremental_downloader_#{mod}_last_run"
        name = "#{mod}-#{DateTime.now.to_i.to_s}.csv"

        last_timestamp = if GoodData::ProjectMetadata.has_key?(md_name)
          DateTime.parse(GoodData::ProjectMetadata[md_name]).iso8601
        end

        puts "Downloading #{mod}"
        result = get_module_changes(client, mod, {:start => last_timestamp})
        updates = result[:updates]
        puts "Downloaded #{updates.count} updates"
        fields = result[:fields]
        last_timestamp = result[:latest_date]  

        CSV.open(name, 'w', :force_quotes => true) do |csv|
          csv << fields
          updates.map do |u|
            csv << u.values_at(*fields)
          end
        end

        memo << {
          :filename => name,
          :state    => [
            {
              :key    => md_name,
              :value  => last_timestamp
            }
          ]
        }
      end
      metadata
    end

    private

    def fields(client, obj)
      description = client.describe(obj)
      description.fields.map {|f| f.name}
    end

    def construct_query(obj, fields, ids)
      "SELECT #{fields.join(', ')} FROM #{obj} WHERE Id IN(#{ids.map {|i| "'" + i + "'"}.join(', ')})"
    end

    def get_module_changes(client, mod, options={})
      slice_size = options[:slice_size] || 50
      start = (options[:start] && DateTime.parse(options[:start]).in_time_zone(TZ).iso8601) || DATE_FROM

      res = client.get("/services/data/v29.0/sobjects/#{mod}/updated/?start=#{start}&end=#{DATE_TO}")
      latest_date = res.body.latestDateCovered
      ids = res.body.ids
      fields = fields(client, mod)

      updates = ids.each_slice(slice_size).reduce([]) do |memo, slice|
        q = construct_query(mod, fields, slice)
        res = client.query(q)
        memo.concat(res.to_a)
      end
      {
        :latest_date => latest_date,
        :updates    => updates,
        :fields     => fields
      }
    end

  end
end