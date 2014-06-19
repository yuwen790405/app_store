# utf-8
require 'open-uri'
require 'csv'
require 'gooddata'

module GoodData::Bricks
  class UserFiltersBrick < GoodData::Bricks::Brick
    def version
      "0.0.1"
    end

    def call(params)
      domain_name = params['domain']
      domain = GoodData::Domain[domain_name] if domain_name

      filters_filepath = params['filters_filepath']
      config = params['filters_setup']

      filters = GoodData::UserFilterBuilder::get_filters(filters_filepath, config);
      GoodData::UserFilterBuilder.execute_mufs(filters_to_load, :domain => domain)
    end
  end
end
