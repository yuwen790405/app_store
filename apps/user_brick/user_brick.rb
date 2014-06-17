# utf-8
require 'open-uri'
require_relative '../../../../gooddata/gooddata-ruby/lib/gooddata'
require 'csv'

module GoodData::Bricks

  class UserBrick < GoodData::Bricks::Brick
    def version
      "0.0.1"
    end

    def call(params)

      domain = params[:domain]
      projectID = params[:project]
      csv_path = params[:csv_path]

      project = GoodData::Project[projectID]

      default_first_name_column = 'first_name'
      default_last_name_column  = 'last_name'
      default_login_column      = 'login'
      default_email_column      = 'email'
      default_password_column   = 'password'
      default_role_column       = 'role'

      first_name_column = params[:first_name_column] || default_first_name_column
      last_name_column  = params[:last_name_column] || default_last_name_column
      login_column      = params[:login_column] || default_login_column
      password_column   = params[:password_column] || default_password_column
      email_column      = params[:email_column] || default_email_column || default_login_column
      role_column       = params[:role_column] || default_role_column

      # Check mandatory columns and parameters
      mandatory_params = [domain, project]

      mandatory_params.each do |param|
        fail param+' is required in the block parameters.' unless param
      end

      new_users = []
      CSV.foreach(csv_path, :headers => true, :return_headers => false) do |row|
      pp row
        json = {
            'user' => {
                'content' => {
                    'firstname' => row[first_name_column],
                    'lastname' => row[last_name_column],
                    'login' => row[login_column],
                    'password' => row[password_column],
                    'email' => row[email_column],
                    'role' => row[role_column],
                    'domain' => domain
                },
                'meta' => {}
            }
        }

        new_users << GoodData::Membership.new(json)

      end

      pp new_users

      project.users_import(new_users)

    end

  end

end



#GoodData.connect('patrick.mcconlogue@gooddata.com','notapassword')
#
#params = {
#    :domain => "ex34am34pl34e34do34ma34in",
#    :project => "a97oln5yik7lwgjbucw7zbo1ioodkpip",
#    :csv_path => "./demo.csv"
#}
#
#GoodData::Bricks::UserBrick.new().call(params)