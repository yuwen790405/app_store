module GoodData
  class Schedule
    # Executes schedule
    #
    # @return [Object] Raw Response
    def execute_no_wait
      data = {
          :execution => {}
      }
      execution = client.post(execution_url, data)
    end
  end
end

module GoodData::Bricks

  class ExecuteBrick < GoodData::Bricks::Brick

    def call(params)
      logger = params['GDC_LOGGER']

      raise Exception,"The parameter LIST_OF_MODES need to be filled" if !params.include?("LIST_OF_MODES")
      raise Exception,"The parameter WORK_DONE_IDENTIFICATOR need to be filled" if !params.include?("WORK_DONE_IDENTIFICATOR")
      list_of_modes = params["LIST_OF_MODES"].split("|")
      work_done_identificator = params["WORK_DONE_IDENTIFICATOR"]
      number_of_schedules_in_batch = Integer(params["NUMBER_OF_SCHEDULES_IN_BATCH"]) || 1000
      delay_between_batches = Integer(params["DELAY_BETWEEN_BATCHES"]) || 0

      # The WORK_DONE_IDENTIFICATOR is flag which tells the executor to execute the schedules
      # It could have special value IGNORE. In this case all corresponding schedules will be started during every run of this brick
      start_schedules = false
      if (work_done_identificator != "IGNORE")
        if (GoodData.project.metadata.key?(work_done_identificator))
          start_schedules = (GoodData.project.metadata[work_done_identificator] == "true")
        end
      elsif (work_done_identificator == "IGNORE")
        start_schedules = true
      end
      if (start_schedules)
        schedules_to_start = []
        GoodData::Project.all.each do |project|
          project.schedules.each do |s|
            if (s.params.include?("MODE"))
              if (list_of_modes.include?(s.params["MODE"]))
                schedules_to_start << {:schedule => s,:project => project}
              end
            end
          end
        end
        batch_number = 1
        schedules_to_start.each_slice(number_of_schedules_in_batch) do |batch_schedules|
          logger.info "Starting batch number #{batch_number}. Number of schedules in batch #{batch_schedules.count}."
          batch_schedules.each do |hash|
            begin
              tries ||= 5
              logger.info "Starting schedule for project #{hash[:project].pid} - #{hash[:project].title}. Schedule ID is #{hash[:schedule].obj_id}"
              hash[:schedule].execute_no_wait
            rescue => e
              if (tries -= 1) > 0
                logger.warn "There was error during operation: #{e.message}. Retrying"
                sleep(5)
                retry
              else
                logger.info "We could not start schedule for project #{hash[:project].pid} - #{hash[:project].title} - #{e.message}"
              end
            else
              logger.info "Operation finished"
            end
          end
          logger.info "Entering sleep mode for #{delay_between_batches} seconds"
          batch_number += 1
          sleep(delay_between_batches)
        end
        GoodData.project.set_metadata(work_done_identificator,"false")
      end
    end
  end


  class GoodDataCustomMiddleware < GoodData::Bricks::Middleware
    def call(params)
      logger = params['GDC_LOGGER']
      token_name = 'GDC_SST'
      protocol_name = 'CLIENT_GDC_PROTOCOL'
      server_name = 'CLIENT_GDC_HOSTNAME'
      project_id = params['GDC_PROJECT_ID']

      server = if params[protocol_name] && params[server_name]
                 "#{params[protocol_name]}://#{params[server_name]}"
               end

      client = if params['GDC_USERNAME'].nil? || params['GDC_PASSWORD'].nil?
                 puts "Connecting with SST to server #{server}"
                 fail 'SST (SuperSecureToken) not present in params' if params[token_name].nil?
                 GoodData.connect(sst_token: params[token_name], server: server)
               else
                 puts "Connecting as #{params['GDC_USERNAME']} to server #{server}"
                 GoodData.connect(params['GDC_USERNAME'], params['GDC_PASSWORD'], server: server)
               end
      project = client.projects(project_id)
      GoodData.project = project
      GoodData.logger = logger
      @app.call(params.merge!('GDC_GD_CLIENT' => client, 'gdc_project' => project))
    end
  end



end