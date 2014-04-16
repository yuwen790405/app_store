require 'restforce'
require 'pry'
require 'active_support/all'
require 'csv'
require 'gooddata'
require './downloader'

# TODO:

module GoodData::Bricks

  class SalesForceHistoryBrick

    def call(params)
      GoodData::Bricks::SalesForceHistoryDownloader.new(params).run
    end
  end
end

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  #GoodDataMiddleware,
  RestForceMiddleware,
  BulkSalesforceMiddleware,
  SalesForceHistoryBrick])

p.call($SCRIPT_PARAMS)