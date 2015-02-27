# encoding: utf-8

require 'gooddata'
require_relative 'users_brick'
require_relative 'vendor/middleware'
require_relative 'vendor/project'
require_relative 'vendor/membership'
require_relative 'vendor/profile'
require_relative 'vendor/helpers'
require_relative 'vendor/domain'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  DecodeParamsMiddleware,
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  FsProjectDownloadMiddleware.new(:source => :staging),
  FsProjectUploadMiddleware.new(:destination => :staging),
  UsersBrick])

p.call($SCRIPT_PARAMS.to_hash)
