require 'restforce'
require 'pry'
require 'active_support/all'
require 'csv'
require 'gooddata'
require 'aws'
require './downloader'

# TODO: 

module GoodData::Bricks

  class SalesForceIncrementalBrick

    def call(params)
      GoodData::Bricks::SalesForceIncrementalDownloader.new(params).run
    end
  end
end

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  RestForceMiddleware,
  SalesForceIncrementalBrick])

p.call($SCRIPT_PARAMS)