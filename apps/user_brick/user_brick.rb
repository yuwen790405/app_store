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
      GoodData.logging_on
      domain_name = params['domain']
      project = params['gdc_project'] || GoodData::Project[params['GDC_PROJECT_ID']]
      csv_path = params['csv_path']
      only_domain = params['add_only_to_domain'] == 'true' || params['add_only_to_domain'] == true ? true : false
      whitelists = params['whitelists']

      # Check mandatory columns and parameters
      mandatory_params = [domain_name, csv_path]

      mandatory_params.each do |param|
        fail param+' is required in the block parameters.' unless param
      end

      domain = GoodData::Domain[domain_name]

      first_name_column   = params['first_name_column'] || 'first_name'
      last_name_column    = params['last_name_column'] || 'last_name'
      login_column        = params['login_column'] || 'login'
      password_column     = params['password_column'] || 'password'
      email_column        = params['email_column'] || 'email'
      role_column         = params['role_column'] || 'role'
      sso_provider_column = params['sso_provider_column'] || 'sso_provider'


      sso_provider = params['sso_provider']
      ignore_failures = params['ignore_failures'] == "true" || params['ignore_failures'] == true ? true : false

      new_users = []
      
      CSV.foreach(File.open(csv_path, 'r:UTF-8'), :headers => true, :return_headers => false, encoding:'utf-8') do |row|
        
        json = {
          'user' => {
            'content' => {
              'firstname' => row[first_name_column],
              'lastname' => row[last_name_column],
              'login' => row[login_column],
              'password' => row[password_column],
              'email' => row[email_column] || row[login_column],
              'role' => row[role_column],
              'domain' => domain_name,
              'sso_provider' => sso_provider || row[sso_provider_column]
            },
            'meta' => {}
          }
        }
        new_users << GoodData::Membership.new(json)
      end
      if only_domain
        domain.users_create(new_users, :ignore_failures => ignore_failures)
      else
        project.users_import(new_users, domain: domain, :whitelists => whitelists, :ignore_failures => ignore_failures)
      end
    end
  end
end
