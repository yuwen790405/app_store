require 'gooddata'
require 'logger'

module GoodData::Bricks
  class HelloWorldBrick

    def call(params)
      logger = Logger.new(STDOUT)
      logger.info "Hello world"
      logger.info params
    end

  end
end

b = GoodData::Bricks::HelloWorldBrick.new
b.call($SCRIPT_PARAMS)