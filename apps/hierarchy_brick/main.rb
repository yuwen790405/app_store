# encoding: utf-8

require 'gooddata'
require_relative 'hierarchy_brick'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  DecodeParamsMiddleware,
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  FsProjectDownloadMiddleware.new(:source => :staging),
  FsProjectUploadMiddleware.new(:destination => :staging),
  HierarchyBrick
])

p.call($SCRIPT_PARAMS.to_hash)
