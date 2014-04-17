require 'gooddata'
require 'restforce'
require '../salesforce_history_downloader/downloader'
require '../dss_execute/executor'
include GoodData::Bricks

module GoodData::Bricks

  class SalesForceHistoryMiddleware < GoodData::Bricks::Middleware
    def call(params)
      downloaded_fields = GoodData::Bricks::SalesForceHistoryDownloader.new(params).run
      @app.call(params.merge(:salesforce_downloaded_fields => downloaded_fields))
    end
  end

  class SaveToDssBrick
    def call(params)
      executor = GoodData::Bricks::DssExecutor.new(params)

      # create dss tables
      executor.create_tables(params[:salesforce_downloaded_fields])

      # load the data
      executor.load_data(params[:salesforce_downloaded_fields])

    end
  end
end

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  RestForceMiddleware,
  BulkSalesforceMiddleware,
  SalesForceHistoryMiddleware,
  SaveToDssBrick
])

p.call($SCRIPT_PARAMS)