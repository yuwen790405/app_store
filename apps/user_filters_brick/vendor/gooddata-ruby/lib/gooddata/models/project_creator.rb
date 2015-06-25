# encoding: UTF-8

require_relative 'project'
require_relative 'blueprint/project_blueprint'

require 'open-uri'

module GoodData
  module Model
    class ProjectCreator
      class << self
        def migrate(opts = {})
          opts = { client: GoodData.connection }.merge(opts)
          client = opts[:client]
          fail ArgumentError, 'No :client specified' if client.nil?

          spec = opts[:spec] || fail('You need to provide spec for migration')
          bp = ProjectBlueprint.new(spec)
          fail GoodData::ValidationError, "Blueprint is invalid #{bp.validate.inspect}" unless bp.valid?
          spec = bp.to_hash
          token = opts[:token]
          project = opts[:project] || client.create_project(:title => spec[:title], :auth_token => token, :client => client)
          fail('You need to specify token for project creation') if token.nil? && project.nil?

          begin
            migrate_datasets(spec, opts.merge(project: project, client: client))
            load(p, spec)
            migrate_metrics(p, spec[:metrics] || [])
            migrate_reports(p, spec[:reports] || [])
            migrate_dashboards(p, spec[:dashboards] || [])
            execute_tests(p, spec[:assert_tests] || [])
            project
          end
        end

        def migrate_datasets(spec, opts = {})
          opts = { client: GoodData.connection }.merge(opts)
          client = opts[:client]
          dry_run = opts[:dry_run]
          fail ArgumentError, 'No :client specified' if client.nil?

          p = opts[:project]
          fail ArgumentError, 'No :project specified' if p.nil?

          project = client.projects(p)
          fail ArgumentError, 'Wrong :project specified' if project.nil?
          bp = ProjectBlueprint.new(spec)
          uri = "/gdc/projects/#{project.pid}/model/diff"
          result = client.post(uri, bp.to_wire)

          link = result['asyncTask']['link']['poll']
          response = client.get(link, :process => false)

          while response.code != 200
            sleep 1
            GoodData::Rest::Client.retryable(:tries => 3) do
              sleep 1
              response = client.get(link, :process => false)
            end
          end

          response = client.get(link)

          chunks = pick_correct_chunks(response['projectModelDiff']['updateScripts'])
          if !chunks.nil? && !dry_run
            chunks['updateScript']['maqlDdlChunks'].each do |chunk|
              result = project.execute_maql(chunk)
              fail 'Creating dataset failed' if result['wTaskStatus']['status'] == 'ERROR'
            end
          end
          chunks
        end

        def migrate_reports(project, spec)
          spec.each do |report|
            project.add_report(report)
          end
        end

        def migrate_dashboards(project, spec)
          spec.each do |dash|
            project.add_dashboard(dash)
          end
        end

        def migrate_metrics(project, spec)
          spec.each do |metric|
            project.add_metric(metric)
          end
        end

        def load(project, spec)
          if spec.key?(:uploads) # rubocop:disable Style/GuardClause
            spec[:uploads].each do |load|
              schema = GoodData::Model::Schema.new(spec[:datasets].find { |d| d[:name] == load[:dataset] })
              project.upload(load[:source], schema, load[:mode])
            end
          end
        end

        def execute_tests(_project, spec)
          spec.each do |assert|
            result = GoodData::ReportDefinition.execute(assert[:report])
            fail "Test did not pass. Got #{result.table.inspect}, expected #{assert[:result].inspect}" if result.table != assert[:result]
          end
        end

        def pick_correct_chunks(chunks)
          # first is cascadeDrops, second is preserveData
          rules = [
            [false, true],
            [false, false],
            [true, true],
            [true, false]
          ]
          stuff = chunks.select { |chunk| chunk['updateScript']['maqlDdlChunks'] }
          rules.reduce(nil) do |a, e|
            a || stuff.find { |chunk| e[0] == chunk['updateScript']['cascadeDrops'] && e[1] == chunk['updateScript']['preserveData'] }
          end
        end
      end
    end
  end
end
