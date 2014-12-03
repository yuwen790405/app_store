# encoding: utf-8

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
            case destination.to_s
            when 'staging'
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
