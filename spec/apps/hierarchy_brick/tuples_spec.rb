require 'gooddata'
$LOAD_PATH.unshift(File.expand_path('../../../..', __FILE__))
require './apps/hierarchy_brick/hierarchy_brick'
include GoodData::Bricks

DATA_CLOSURE_TUPLE = [
  ['user_id', 'subordinate_id'],
  ['A', 'B'],
  ['A', 'C'],
  ['A', 'D'],
  ['A', 'E'],
  ['A', 'A'],
  ['B', 'D'],
  ['B', 'E'],
  ['B', 'B'],
  ['C', 'C'],
  ['D', 'D'],
  ['E', 'E']
]

DATA_CLOSURE = [
  ['A', 'B', 'C', 'D', 'E', 'A'],
  ['B', 'D', 'E', 'B'],
  ['C', 'C'],
  ['D', 'D'],
  ['E', 'E']
]

DATA_FIXED_LEVEL = [
  ['level_1', 'level_2', 'level_3', 'level'],
  ['A', 'A', 'A', '1'],
  ['A', 'B', 'B', '2'],
  ['A', 'C', 'C', '2'],
  ['A', 'B', 'D', '3'],
  ['A', 'B', 'E', '3']
]

DATA_FIXED_LEVEL_WITH_OUTPUT_FIELD = [
  ['level_1', 'level_2', 'level_3', 'level', 'name'],
  ['A', 'A', 'A', '1', 'Tomas'], 
  ['A', 'B', 'B', '2', 'Patrick'],
  ['A', 'C', 'C', '2', 'Petr'],
  ['A', 'B', 'D', '3', 'John'],
  ['A', 'B', 'E', '3', 'Seth']
]


describe GoodData::Schedule do

  before(:each) do
    @params = {
      'input_file' => 'spec/apps/hierarchy_brick/input.csv',
      'output_file' => StringIO.new,
      'config' => {
        'id' => 'id',
        'manager_id' => 'parent_id'
      }
    }
  end

  it 'should compute closure tuple hierarchy' do
    @params['hierarchy_type'] = :subordinates_closure_tuples

    result = HierarchyBrick.new.call(@params)
    data = CSV.parse(result.first[:path].string)
    expect(data).to eq DATA_CLOSURE_TUPLE
  end

  it 'should compute closure hierarchy' do
    @params['hierarchy_type'] = :subordinates_closure

    result = HierarchyBrick.new.call(@params)
    data = CSV.parse(result.first[:path].string)
    expect(data).to eq DATA_CLOSURE
  end

  it 'should compute fixed level hierarchy' do
    @params['hierarchy_type'] = :fixed_level

    result = HierarchyBrick.new.call(@params)
    data = CSV.parse(result.first[:path].string)
    expect(data).to eq DATA_FIXED_LEVEL
  end

  it 'should compute fixed level hierarchy with some additional fields' do
    @params['hierarchy_type'] = :fixed_level
    @params['output_fields'] = ['name']

    result = HierarchyBrick.new.call(@params)
    data = CSV.parse(result.first[:path].string)
    expect(data).to eq DATA_FIXED_LEVEL_WITH_OUTPUT_FIELD
  end
end
