require 'gooddata'
require '../dss_execute/executor'

include GoodData::Bricks

module GoodData::Bricks
  # takes stuff from dss and puts it into a csv
  class ExtractFromDssMiddleware #< GoodData::Bricks::Middleware
    def call(params)
      executor = GoodData::Bricks::DssExecutor.new(params)

      executor.extract_data(params["gooddata_datasets"])
    end
  end
end

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  ExtractFromDssMiddleware,

])

p.call($SCRIPT_PARAMS)