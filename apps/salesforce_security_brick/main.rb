# encoding: utf-8

require 'gooddata'
require './salesforce_security_brick'
require './middleware'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  FsProjectDownloadMiddleware.new(:source => :staging),
  FsProjectUploadMiddleware.new(:destination => :staging),
  SalesforceSecurityBrick
])

params = $SCRIPT_PARAMS.to_hash
expanded_params = params.merge(MultiJson.load(params["params"]))
p.call(expanded_params)
