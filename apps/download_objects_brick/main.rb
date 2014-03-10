require 'gooddata'

module GoodData::Bricks

  class DownloadObjectsBrick < GoodData::Bricks::Brick

    DEFAULT_FIELDS = ["type", "uri", "title", "summary", "tags"]

    def version
      "0.0.1"
    end

    def call(params)

      path = params[:download_objects_output_file]
      fail "You need to specify a path to save the data to" if path.nil? || path.empty?

      CSV.open(path, "w") do |csv|
        csv << DEFAULT_FIELDS
        GoodData::Report[:all].each do |report|
          csv << report.values_at("link", "title", "summary", "tags").unshift("report")
        end
      end

    end
  end
end


include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  DownloadObjectsBrick])

params = $SCRIPT_PARAMS.to_hash.symbolize_keys
params = params.merge({:GDC_SERVER => params[:GDC_HOSTNAME] })

p.call(params)