# encoding: utf-8
require 'bundler/cli'
Bundler::CLI.new.invoke(:install, [], path: 'gems', verbose: true)
require 'bundler/setup'
require 'gooddata'
require 'user_hierarchies'

require_relative 'hierarchy_brick'
require_relative 'vendor/dwh_middleware'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  DecodeParamsMiddleware,
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  WarehouseMiddleware,
  FsProjectUploadMiddleware.new(destination: :staging),
  HierarchyBrick
])

p.call($SCRIPT_PARAMS.to_hash)
