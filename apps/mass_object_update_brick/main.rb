require 'gooddata'

module GoodData::Bricks

  class MassObjectUpdateBrick < GoodData::Bricks::Brick

    DEFAULT_FIELDS = ["type", "uri", "title", "summary", "tags"]

    def version
      "0.0.1"
    end

    def call(params)

      path = params[:mass_object_update_input_file]
      fail "You need to specify a path to save the data to" if path.nil? || path.empty?

      CSV.foreach(open(path), :headers => true, :return_headers => false) do |row|
        obj = case row["type"]
        when "report"
          GoodData::Report[row["uri"]]
        end
        obj.title = row["title"]
        obj.summary = row["summary"]
        obj.tags = row["tags"]
        obj.save
      end
    end
  end
end

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  MassObjectUpdateBrick])

p.call($SCRIPT_PARAMS)
