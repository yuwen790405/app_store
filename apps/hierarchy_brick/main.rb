require 'gooddata'
require './hierarchy_brick'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  HierarchyBrick
])

p.call($SCRIPT_PARAMS)
