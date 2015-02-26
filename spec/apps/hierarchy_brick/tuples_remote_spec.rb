require 'gooddata'

describe GoodData::Schedule do

  before(:all) do
    GoodData.logging_on
    @client = GoodData.connect('svarovsky+gem_tester@gooddata.com', '')
    @project = @client.create_project(title: 'Project for schedule testing', auth_token: '')
  end
  
  after(:all) do
    @project && @project.delete
  end

  it 'should compute closure tuple hierarchy' do
    GoodData.upload_to_project_webdav('spec/apps/hierarchy_brick/input.csv', project: @project)
    process = @project.deploy_process('./apps/hierarchy_brick', :name => 'Hierarchy process', type: :ruby)
    process.execute('main.rb', {
      :params => {
        'gdc_files_to_download' => ['input.csv'],
        'input_file' => 'input.csv',
        'output_file' => 'output.csv',
        'config' => {
          'id' => 'id',
          'manager_id' => 'parent_id'
        },
        'hierarchy_type' => 'subordinates_closure_tuples',
        'GDC_USERNAME' => '',
        'GDC_PASSWORD' => ''
      }
    })

    temp_file = Tempfile.new('foo.csv')
    begin
      GoodData.download_from_project_webdav('output.csv', temp_file.path, project: @project)
      x = CSV.parse(File.read temp_file.path)
      expect(x).to eq [
        ["user_id", "subordinate_id"],
        ["A", "B"],
        ["A", "C"],
        ["A", "D"],
        ["A", "E"],
        ["A", "A"],
        ["B", "D"],
        ["B", "E"],
        ["B", "B"],
        ["C", "C"],
        ["D", "D"],
        ["E", "E"]
      ]
      
    ensure
      temp_file.unlink
    end
  end
end
