require 'gooddata'
require './user_brick'
require 'rspec'

describe GoodData::Bricks::UserBrick do


  it 'should change the default column from role to privileges' do

    GoodData.logging_on

    GoodData.connect('svarovsky+gem_tester@gooddata.com','jindrisska')

    # REPLACE with GIST
    #params = {
    #    :domain => "NO",
    #    :project => "NO",
    #    :csv_path => "NO"
    #}
    

    GoodData::Bricks::UserBrick.new().call(params)


    #p = GoodData::Bricks::Pipeline.prepare([brick])

    #p.call(params)

  end

end

# GoodData::Bricks::UserBrick.new().call({ :first_name => 'firstName', :project => '29380f2930', :domain => 'ofsfesesef' })