# encoding: utf-8

require 'gooddata'

module GoodData::Bricks
  class OrchestrationBrick < GoodData::Bricks::Brick

    def version
      '0.0.1'
    end

    def call(params)
      client = params['GDC_GD_CLIENT'] || fail('client needs to be passed into a brick as "GDC_GD_CLIENT"')
      project = client.projects(params['gdc_project']) || client.projects(params['GDC_PROJECT_ID'])
      definition = params['definition']
      
      schedules = project.schedules.to_a;
      definition.each do |schedule_name, deps|
        s = schedules.find { |s| s.name == schedule_name }
        fail "There is rule referencing schedule \"#{schedule_name}\". This schedule does not seem to exist in project #{project.pid}." if s.nil?
        fail "Schedules have to set \"reschedule\" parameter to zero (or empty) so the automatic rescheduling on failure does not kick in. Schedule \"#{s.name}\" is violating this" unless s.reschedule.nil? || s.reschedule == 0
      end

      running = []
      done = []
      restarts = Hash.new(1)
      loop do
        refreshed_running = running.map { |r| r.merge(execution: client.create(GoodData::Execution, (client.get(r[:execution].uri)), project: project))}
        just_finished = refreshed_running.select { |s| s[:execution].ok? }
        just_finished.each { |s| puts "Process finished \"#{s[:rule].first}\" #{s[:execution].uri}" }
        done = done + just_finished

        failed = refreshed_running.select { |s| s[:execution].error? }
        failed.each do |failed_schedule|
          execution = failed_schedule[:execution]
          rule = failed_schedule[:rule]
          uri = execution.uri
          restarts[rule] += 1
          opts = rule[2] || {}
    
          if restarts[rule] > (opts['retries'] || 1)
            fail "Process \"#{rule.first}\" failed"
          else
            puts "Process \"#{rule.first}\" failed. Restarting process. Attempt #{restarts[rule]}."
            running.find { |process| process[:rule] == rule }[:execution] = execution.schedule.execute(wait: false)
          end
        end
  
        running = running.reject { |process| done.map { |d| d[:execution].uri }.include?(process[:execution].uri) }

        definition = definition.reject {|rule| (done).find { |process| process[:rule] == rule } }
        can_run = definition.reject { |rule| definition.find {|d| rule[1].include?(d.first) }}.reject {|rule| running.find {|run| run[:rule] == rule}}
        running = running + can_run.map {|rule| puts "Running #{rule}"; { rule: rule, execution: project.schedules.find {|s| s.name == rule.first}.execute(wait: false) }}
        break if definition.empty? && running.empty?
        sleep 10
      end

      puts "Definition succesfully executed"
    end
  end
end
