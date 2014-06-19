# utf-8
require 'open-uri'
require 'csv'
require 'gooddata'

module GoodData::Bricks

  class UserBrick < GoodData::Bricks::Brick
    def version
      "0.0.1"
    end

    def call(params)

      domain_name = params['domain']
      project = params['gdc_project']
      csv_path = params['csv_path']
      only_domain = params['add_only_to_domain'] == 'true' || params['add_only_to_domain'] == true ? true : false
      whitelists = params['whitelists']

      # Check mandatory columns and parameters
      mandatory_params = [domain_name, csv_path]

      mandatory_params.each do |param|
        fail param+' is required in the block parameters.' unless param
      end

      domain = GoodData::Domain[domain_name]

      first_name_column = params[:first_name_column] || 'first_name'
      last_name_column  = params[:last_name_column] || 'last_name'
      login_column      = params[:login_column] || 'login'
      password_column   = params[:password_column] || 'password'
      email_column      = params[:email_column] || 'email' || default_login
      role_column       = params[:role_column] || 'role'

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
              'domain' => domain_name
            },
            'meta' => {}
          }
        }
        new_users << GoodData::Membership.new(json)
      end

      if only_domain
        domain.users_create(new_users)
      else
        project.users_import(new_users, domain: domain, :whitelists => whitelists)
      end
    end
  end
end
