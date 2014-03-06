require 'open-uri'

module GoodData::Bricks

  class UploadDataBrick < GoodData::Bricks::Brick

    def version
      "0.0.1"
    end

    def call(params)

      token = params[:gooddata_project_creation_token]
      fail "You need to have token to be able to create a project" if token.nil? || token.empty?

      spec_uri = params[:gooddata_project_spec_uri]
      spec_type = params[:gooddata_projec_spec_type]

      spec = params[:gooddata_projec_spec]

      spec = spec.nil? ? get_spec(spec_uri, spec_type) : spec

      GoodData::Model::ProjectCreator.migrate(:spec => spec, :token => token)
    end

    def get_spec(spec_uri, spec_type)
      begin
        spec_source = open(spec_uri).read
      rescue OpenURI::HTTPError => e
        fail "Remote file \"#{spec_uri}\" was not found."
      rescue Errno::ENOENT => e
        fail "Local file \"#{spec_uri}\" was not found."
      end
      spec = if spec_type == "rb"
        eval(spec_source)
      else
        spec_source
      end
    end

  end

end