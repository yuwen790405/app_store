require 'gooddata'
require 'logger'

module GoodData::Bricks
  class HelloWorldBrick

    def call(params)
      logger = Logger.new(params[:GDC_LOGGER_FILE])
      logger.info "Hello world"
    end

  end
end

GoodData::Bricks::HelloWorldBrick.new