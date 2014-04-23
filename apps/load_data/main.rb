require 'gooddata'

module GoodData::Bricks

  class LoadDataBrick < GoodData::Bricks::Brick

    def version
      "0.0.1"
    end

    def call(params)

      dataset = params[:load_data_brick_dataset]
      fail "You need to have load_data_brick_dataset set" if dataset.nil? || dataset.empty?

      path = params[:load_data_brick_path]
      fail "You need to have load_data_brick_path set" if path.nil? || path.empty?

      manifest = JSON.parse(GoodData::ProjectMetadata["manifest_#{dataset}"])

      GoodData::Model::upload_data(path, manifest)
    end
  end
end


include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  LoadDataBrick])

p.call($SCRIPT_PARAMS)