require 'gooddata'
require '../dss_execute/executor'

include GoodData::Bricks

module GoodData::Bricks
  # takes stuff from dss and puts it into a csv
  class ExtractFromDssMiddleware < GoodData::Bricks::Middleware
    def call(params)
      executor = GoodData::Bricks::DssExecutor.new(params)

      extended_datasets = executor.extract_data(params["gooddata_datasets"])
      @app.call(params.merge({"gooddata_datasets" => extended_datasets}))
    end
  end

  # takes csvs and loads them to gd
  class LoadToGoodDataBrick
    def call(params)

      # get gd-rubygem's representation of the model
      datasets_repre = params["gooddata_datasets"].map do |ds_name, ds_structure|

        # converting the datasets
        {:name => ds_name, :columns => ds_structure["fields"].map do |col|

          # converting the columns - leaving all as it is, just short_identifier to name (add the key there)
          {:name => col["gooddata"]["short_identifier"]}.merge(
            Hash[col["gooddata"].map {|k,v| [k.to_sym, v]}]
          )
        end}
      end

      model = GoodData::Model::ProjectBlueprint.new({
        :datasets => datasets_repre
      })

      # for each defined dataset
      params["gooddata_datasets"].each do |dataset, ds_structure|
        # get it from the model and load it
        ds = model.get_dataset(dataset)
        ds.upload(ds_structure["csv_filename"])
      end
    end
  end
end

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  ExtractFromDssMiddleware,
  GoodDataMiddleware,
  LoadToGoodDataBrick
])

p.call($SCRIPT_PARAMS)