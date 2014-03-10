require 'pry'
require 'active_support/all'
require 'csv'
require 'gooddata'
require 'open-uri'

def get_header(file)
  header = nil
  open(file) {|f|
    f.each_line do |line|
      header = CSV.parse(line).first
      break
    end
  }
  header
end

module GoodData::Bricks

  class SalesforceProcessorBrick

    def call(params)
      files_to_process = params[:files_to_process]
      files_to_process.each do |file|
        headers = get_header(file)
        begin
          column_files = headers.reduce({}) {|memo, h| memo[h] = File.open("#{h}.csv", "w"); memo}
          open(file) {|f|
            CSV.new(f, :headers => true, :return_headers => false).each do |row|
              headers.each do |h|
                column_files[h].puts([h, row[h], row["Id"], row["SystemModstamp"]].to_csv)
              end
            end
          }
        ensure
          column_files.each_pair {|k, f| f && f.close}
        end
      end

    end
  end
end


include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  SalesforceProcessorBrick])

p.call($SCRIPT_PARAMS)