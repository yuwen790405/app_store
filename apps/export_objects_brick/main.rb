require "gooddata"
require "gooddata/bricks/bricks"
require "./export_objects"

params = $SCRIPT_PARAMS.to_hash
params = params.merge({"GDC_SERVER" => params["GDC_HOSTNAME"] })
destination = params["GDC_ENV_LOCAL"] ? :local : :staging

include GoodData::Bricks
p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  FsUploadMiddleware.new(:destination => :staging),
  ExportObjectsBrick])

p.call(params)