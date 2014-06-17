require 'gooddata'
require './user_brick'
require 'rspec'

describe GoodData::Bricks::UserBrick do

  it 'should change the default column from role to privileges' do

    GoodData.logging_on

    GoodData.connect('')

    demo_csv = 'email,login,first_name,last_name,privileges,password,\ntomas@gooddata.com,tomas777,tomas,svarovsky,Adminstrator,password123,\npatrick@gooddata.com,patrick1,patrick,mcconlogue,Viewer,notapassword1,\nmark@gooddata.com,mark_hamil,mark,hamil,Viewer,anotherpassword'

    params = {
        :domain => "ex34am34pl34e34do34ma34in",
        :project => "tlwlkjw9ccmu2wrev9faq9wryybhar0u",
        :csv_path => demo_csv
    }

    brick = GoodData::Bricks::UserBrick.new().call(params)

    #p = GoodData::Bricks::Pipeline.prepare([brick])

    #p.call(params)

  end

end

# GoodData::Bricks::UserBrick.new().call({ :first_name => 'firstName', :project => '29380f2930', :domain => 'ofsfesesef' })