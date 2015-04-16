# encoding: utf-8
require 'bundler/cli'
Bundler::CLI.new.invoke(:install, [], path: 'gems', verbose: true)
require 'bundler/setup'
require 'gooddata'

require_relative 'feature_flag_brick'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  DecodeParamsMiddleware,
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  FeatureFlagBrick])

p.call($SCRIPT_PARAMS.to_hash)
