require 'gooddata'
require './salesforce_security_brick'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  SalesforceSecurityBrick
])

p.call($SCRIPT_PARAMS)
