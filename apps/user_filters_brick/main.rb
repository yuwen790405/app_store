require 'gooddata'
require './user_filters'
require './middleware'
require './project'
require './user_filters_brick'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  FsProjectDownloadMiddleware.new(:source => :staging),
  FsProjectUploadMiddleware.new(:destination => :staging),
  UserFiltersBrick])

params = $SCRIPT_PARAMS.to_hash
expanded_params = params.merge(MultiJson.load(params["params"]))
p.call(expanded_params)
