require 'gooddata'
$LOAD_PATH.unshift(File.expand_path('../../../..', __FILE__))
require './apps/users_brick/users_brick'

include GoodData::Bricks

def find_unused_domain_name(domain)
  loop do
    name = "brick_test_#{rand(1000000)}@gooddata.com"
    break name unless domain.member?(name)
  end
end

describe GoodData::Bricks::UsersBrick do

  before(:all) do
    @client = GoodData.connect('svarovsky+gem_tester@gooddata.com', '')
    @project_1 = @client.create_project(title: 'Project app_store testing 1', auth_token: '')
    @project_2 = @client.create_project(title: 'Project app_store testing 2', auth_token: '')
    @domain = @client.domain('gooddata-tomas-svarovsky')
  end

  after(:each) do
    @project_1.users.reject { |u| u.login == @client.user.login }.pmap(&:disable)
  end

  after(:all) do
    @project_1 && @project_1.delete
    @project_2 && @project_2.delete
  end

  it 'should add users to project from damain' do
    users = @domain.users.sample(10)
    begin
      tempfile = Tempfile.new('project_sync')

      headers = [:first_name, :last_name, :login, :password, :email, :role, :sso_provider]
      CSV.open(tempfile.path, 'w') do |csv|
        csv << headers
        users.each do |u|
          csv << u.to_hash.merge({role: 'admin'}).values_at(*headers)
        end
      end

      UsersBrick.new.call(
        'GDC_GD_CLIENT' => @client,
        'gdc_project' => @project_1.pid,
        'domain' => @domain.name,
        'csv_path' => tempfile.path
      )
    ensure
      tempfile.unlink
    end
    users = @project_1.users
    expect(users.count).to eq 11
    expect(users.all?(&:enabled?)).to be_truthy
    expect(users.pmap(&:role).map(&:identifier).uniq.count).to eq 1
  end

  it 'should be able to add users to domain' do
    domain = @client.domain('gooddata-tomas-svarovsky')
    user_name = find_unused_domain_name(@domain)
    begin
      tempfile = Tempfile.new('domain_sync')
      CSV.open(tempfile.path, 'w') do |csv|
        csv << [:login]
        csv << [user_name]
      end
      UsersBrick.new.call(
        'GDC_GD_CLIENT'       => @client,
        'gdc_project'         => @project_1.pid,
        'domain'              => @domain.name,
        'csv_path'            => tempfile.path,
        'sync_mode'           => 'add_only_to_domain'
      )
    ensure
      tempfile.unlink
    end
    expect(@domain.member?(user_name)).to be_truthy
    expect(@project_1.member?(user_name)).to be_falsey
  end

  it 'should be able to add users to multiple projects' do
    users = @domain.users.sample(10)
    headers = [:pid, :first_name, :last_name, :login, :password, :email, :role, :sso_provider]
    projects = [@project_1, @project_2]
    users_data = users.map { |u| u.to_hash.merge(pid: projects.sample.pid, role: 'admin') }
    
    begin
      tempfile = Tempfile.new('multiproject_sync')
      CSV.open(tempfile.path, 'w') do |csv|
        csv << headers
        users_data.each do |u|
          csv << u.values_at(*headers)
        end
      end

      UsersBrick.new.call(
        'GDC_GD_CLIENT' => @client,
        'gdc_project' => @project_1.pid,
        'domain' => @domain.name,
        'csv_path' => tempfile.path,
        'multiple_projects_column' => 'pid',
        'sync_mode' => 'sync_multiple_projects_based_on_pid'
      )

      test_data = users_data.group_by { |u| u[:pid] }.map { |pid, u| [pid, u.count] }
      test_data.each do |pid, count|
        expect(@client.projects(pid).users.count).to eq (count + 1)
      end
    ensure
      tempfile.unlink
    end
  end
end
