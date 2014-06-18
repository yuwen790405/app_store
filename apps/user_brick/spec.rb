require 'gooddata'
require './user_brick'
require 'rspec'

describe GoodData::Bricks::UserBrick do

  it 'should change the default column from role to privileges' do

    GoodData.logging_on

    GoodData.connect('svarovsky+gem_tester@gooddata.com', 'jindrisska')


    params = {
        :domain => "gooddata-tomas-svarovsky",
        :project => "pua4g8eplv06iayn5nkz0brqnb5l7i70",
        :csv_path => "./demo.csv"
    }

    GoodData::Bricks::UserBrick.new().call(params)


    #p = GoodData::Bricks::Pipeline.prepare([brick])

    #p.call(params)

  end

end

# GoodData::Bricks::UserBrick.new().call({ :first_name => 'firstName', :project => '29380f2930', :domain => 'ofsfesesef' })