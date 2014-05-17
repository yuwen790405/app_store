require 'gooddata'
require 'restforce'
require 'json'
require '../salesforce_history_downloader/downloader'
require '../dss_execute/executor'
include GoodData::Bricks

Restforce.configure do |config|
  config.api_version = '29.0'
  config.timeout = 30
end

module GoodData::Bricks

  # Downloading from SFDC
  class SalesForceDownloaderMiddleware < GoodData::Bricks::Middleware
    def call(params)
      downloaded_info = GoodData::Bricks::SalesForceHistoryDownloader.new(params).run
      params["GDC_LOGGER"].info "Download finished. This is the info (use in params if you want to upload later: #{JSON.pretty_generate({:salesforce_downloaded_info => downloaded_info})}" if params["GDC_LOGGER"]
      @app.call(params.merge(:salesforce_downloaded_info => downloaded_info))
    end
  end

  # Saving to DSS
  class SaveToDssBrick
    def call(params)
      executor = GoodData::Bricks::DssExecutor.new(params)
      downloaded_info = params[:salesforce_downloaded_info]
      # create dss tables
      executor.create_tables(downloaded_info[:objects])

      # load the data
      executor.load_data(downloaded_info)
    end
  end
end

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  RestForceMiddleware,
  BulkSalesforceMiddleware,
  SalesForceDownloaderMiddleware,
  SaveToDssBrick
])

p.call($SCRIPT_PARAMS)