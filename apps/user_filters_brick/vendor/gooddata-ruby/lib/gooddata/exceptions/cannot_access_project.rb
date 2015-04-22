# encoding: UTF-8

module GoodData
  class UnableToAccessProject < RuntimeError
    attr_reader :project_id 

    def initialize(project_id = 'N/A')
      @project_id = project_id
      super("Project \"#{project_id}\" exists but you are not authorized to access it.")
    end
  end
end
