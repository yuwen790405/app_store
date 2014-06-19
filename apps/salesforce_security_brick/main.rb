require 'gooddata'
require './fixed_level_hierarchy_brick'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  SalesforceSecurityBrick
])

p.call($SCRIPT_PARAMS)
