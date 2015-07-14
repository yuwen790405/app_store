# encoding: utf-8
# Bundler hack
require 'bundler/cli'
Bundler::CLI.new.invoke(:install, [],:path => "gems", :retry => 3, :jobs => 4,:deployment => true)

# Required gems
require 'bundler/setup'
require 'gooddata'

# Require executive brick
require_relative 'execute_brick'

include GoodData::Bricks

# Prepare stack
stack = [
    LoggerMiddleware,
    BenchMiddleware,
    GoodDataCustomMiddleware,
    ExecuteBrick
]

# Create pipeline
p = GoodData::Bricks::Pipeline.prepare(stack)

# Default script params
$SCRIPT_PARAMS = {} if $SCRIPT_PARAMS.nil?

# Setup params
$SCRIPT_PARAMS['GDC_LOGGER'] = Logger.new(STDOUT)

# Execute pipeline
p.call($SCRIPT_PARAMS)
