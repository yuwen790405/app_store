require 'gooddata'
require './project_brick'

include GoodData::Bricks

GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  CreateProjectBrick])