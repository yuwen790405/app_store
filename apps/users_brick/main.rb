# encoding: utf-8

require 'gooddata'
require 'users_brick'
require_relative 'vendor/middleware'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  FsProjectDownloadMiddleware.new(:source => :staging),
  FsProjectUploadMiddleware.new(:destination => :staging),
  UsersBrick])

p.call($SCRIPT_PARAMS.to_hash)
