# utf-8
require 'open-uri'
require 'gooddata'
require 'csv'

module GoodData::Bricks

  class Csv
    class << self
      # Read data from CSV
      #
      # @param [Hash] opts
      # @option opts [String] :path File to read data from
      # @option opts [Boolean] :header File to read data from
      # @return Array of rows with loaded data
      def read(opts)
        path = opts[:path]
        res = []

        line = 0

        CSV.foreach(path) do |row|
          line += 1
          next if opts[:header] && line == 1

          if block_given?
            data = yield row
          else
            data = row
          end

          res << data if data
        end

        res
      end

      # Write data to CSV
      # @option opts [String] :path File to write data to
      # @option opts [Array] :data Mandatory array of data to write
      # @option opts [String] :header Optional Header row
      def write(opts, &block)
        path = opts[:path]
        header = opts[:header]
        data = opts[:data]

        CSV.open(path, 'w') do |csv|
          csv << header unless header.nil?
          data.each do |entry|
            res = yield entry
            csv << res if res
          end
        end
      end
    end
  end

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

      # Check mandatory columns and paramters
      mandatory_params = [domain, project, first_name_column, last_name_column, login_column, password_column]

      mandatory_params.each do |param|
        if param == nil
          fail param+' is required in the block parameters.'
        end
      end

      header_parsed = false

      new_users = Csv.read(:path => csv_path, :header => false) do |row|

        if header_parsed == false
          # TODO: Extract the indices here
          row.each_with_index do |index, item|
            first_name_index = index if item == first_name_column
            last_name_index = index if item == last_name_column
            login_index = index if item == login_column
            password_index = index if item == password_column
            email_index = index if item == email_column
            role_index = index if item == role_column
          end

          header_parsed = true
          next
        end

        json = {
            'user' => {
                'content' => {
                    'firstname' => row[first_name_index],
                    'lastname' => row[last_name_index],
                    'login' => row[login_index],
                    'password' => row[password_index],
                    'email' => row[email_index],
                    'role' => row[role_index],
                    'domain' => domain
                },
                'meta' => {}
            }
        }

        GoodData::Membership.new(json)

      end

      project.users_import(new_users)

    end

  end

end

