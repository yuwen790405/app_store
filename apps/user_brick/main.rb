require 'gooddata'
require './user_brick'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  CreateProjectBrick])

p.call($SCRIPT_PARAMS)