require 'net/dav'

module GoodData
  module Bricks
    # Converts params from encoded hash to decoded hash
    class DecodeParamsMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash

        @app.call(GoodData::Helpers.decode_params(params))
      end
    end
  end
end

module GoodData
  module Helpers
    
    ENCODED_PARAMS_KEY = :gd_encoded_params
    ENCODED_HIDDEN_PARAMS_KEY = :gd_encoded_hidden_params

    def self.decode_params(params)
      key = ENCODED_PARAMS_KEY.to_s
      hidden_key = ENCODED_HIDDEN_PARAMS_KEY.to_s
      data_params = params[key] || '{}'
      hidden_data_params = params[hidden_key] || '{}'

      begin
        parsed_data_params = JSON.parse(data_params)
        parsed_hidden_data_params = JSON.parse(hidden_data_params)
      rescue JSON::ParserError => e
        raise e.class, "Error reading json from '#{key}' or '#{hidden_key}' in params #{params}\n #{e.message}"
      end
      params.delete(key)
      params.delete(hidden_key)
      params.merge(parsed_data_params).merge(parsed_hidden_data_params)
    end
  end
end

module GoodData
  module Bricks
    class FsProjectUploadMiddleware < Bricks::Middleware
      def initialize(options = {})
        super
        @destination = options[:destination]
      end

      def call(params)
        returning(@app.call(params)) do |result|
          destination = @destination
          (params['gdc_files_to_upload'] || []).each do |f|
            path = f[:path]
            case destination.to_sym
            when :staging
              GoodData.client.get '/gdc/account/token', :dont_reauth => true
              url = GoodData.get_project_webdav_path(path)
              GoodData.upload_to_project_webdav(path)
              puts "Uploaded local file \"#{path}\" to url \"#{url + path}\""
            end
          end
        end
      end
    end
  end
end

module GoodData
  module Bricks
    class FsProjectDownloadMiddleware < Bricks::Middleware
      def initialize(options = {})
        super
        @source = options[:source]
      end

      def call(params)
        source = @source
        (params['gdc_files_to_download'] || []).each do |f|
          path = f
          case source.to_s
          when 'staging'
            webdav_uri = GoodData.get_project_webdav_path('')
            dav = Net::DAV.new(webdav_uri, :curl => false)
            dav.verify_server = false
            dav.credentials(params['GDC_USERNAME'], params['GDC_PASSWORD'])
            dav.find(path ,:recursive=>true, :suppress_errors=>true) do | item |
              puts "Checking: " + item.url.to_s
              name = (item.uri - webdav_uri).to_s
              File.open(name, 'w') do |f|
                f << item.content
              end
            end
          end
        end
        @app.call(params)
      end
    end
  end
end

module GoodData
  module Bricks
    class GoodDataMiddleware < Bricks::Middleware
      def call(params)
        logger = params['GDC_LOGGER']
        token_name = 'GDC_SST'
        protocol_name = 'GDC_PROTOCOL'
        server_name = 'GDC_HOSTNAME'
        project_id = params['GDC_PROJECT_ID']

        fail 'SST (SuperSecureToken) not present in params' if params[token_name].nil?

        server = if !params[protocol_name].empty? && !params[server_name].empty?
                   "#{params[protocol_name]}://#{params[server_name]}"
                 end

        client = if params['GDC_USERNAME'].nil? || params['GDC_PASSWORD'].nil?
                   GoodData.connect(sst_token: params['GDC_SST'], server: server)
                 else
                   GoodData.connect(params['GDC_USERNAME'], params['GDC_PASSWORD'], server: server)
                 end
        GoodData.logger = logger
        @app.call(params.merge({
          'GDC_GD_CLIENT' => client,
          'gdc_project' => client.projects(project_id)
        }))
      end
    end
  end
end
