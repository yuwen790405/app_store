
module GoodData::Bricks

  class FeatureFlagBrick < GoodData::Bricks::Brick

    def version
      "0.0.1"
    end

    def call(params)
      fail "You need to have feature_flags parameter present" if params.include?("feature_flags")
      features_flags = params["features_flag"]
      project_id = params['gdc_project'] || params['GDC_PROJECT_ID']
      url = "/gdc/projects/#{project_id.obj_id}/projectFeatureFlags"

      features_flags.each_pair do |tag,value|
        payload = {
         "featureFlag" => {
            "key" => tag,
            "value" => value
          }
        }
        GoodData.post(url,payload)
      end
    end
  end
end
