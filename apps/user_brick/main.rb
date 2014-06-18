require 'gooddata'
require './user_brick'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  UserBrick])

p.call($SCRIPT_PARAMS)