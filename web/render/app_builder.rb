# Renders HTML page of all apps bas on 
require 'rubygems' 
# require 'bundler/setup' 
require 'pp'
require 'json'
require 'find'
require 'pry'

class AppBuilder
    
    @@apps = []

    def render(app_page)
      @app_page = app_page
      @app_name = app_page['name']
      @app_version = app_page['version']
      @app_category = app_page['category']
      @app_language = app_page['language']
      @app_tags = app_page['tags']
      @parameters = app_page['parameters']
      
      begin
        if File.directory?('./pages')
          header = IO.read('./templates/header.html')
          footer = IO.read('./templates/footer.html')
          appPage = File.open("./pages/"+@app_name+".html", "w+")            
          appPage.puts header
          appPage.puts '<p align="center" class="small"> <kbd>Version '+@app_version+'</kbd></p>'
          appPage.puts '<h1 class="cover-heading">'+@app_name.split('_').map(&:capitalize).join(' ')+'</h1>'
          appPage.puts '<p class="lead">'+@app_page["tags"]+'.</p>'

          appPage.puts "<h3>Description</h3>"
          appPage.puts "<div>" + @app_page["description"] + "</div>"

          appPage.puts "<h3>Parameters</h3>"
          appPage.puts '<table id="details" style="width:500px;" align="center" class="table table-condensed">'
          appPage.puts '<tr><td align="left">Name</td><td align="left">Description</td><td>Mandatory</td></tr>'
          @parameters.each do |param|
            appPage.puts '<tr><td align="left">'+param["name"]+'</td><td align="left">'+param["description"]+'</td><td>' + (param["mandatory"] || false).to_s + '</td></tr>'
          end          
          appPage.puts '</table>'
          
          appPage.puts '<p class="lead">Run instructions</p>'
          appPage.puts '<pre>'
          appPage.puts 'cd app_store/apps'
          appPage.puts "bin/gooddata -Ulogin -Ppass -p PROJECT_PID run_ruby --dir #{@app_name}/ --params #{@app_name}/params.json  --name \"Download objects execution\" --remote"
          appPage.puts '</pre>'
          
          appPage.puts '<p class="lead">'+@app_name+'</p>' #more text
          appPage.puts '<a href="'+@app_name+'" class="btn btn-lg btn-default">Install</a></div>' # uri or rel API call. 
          
          
          appPage.puts footer
        else
          Dir.mkdir('pages')
          render(@app_page)
        end
      rescue IOError => e
      ensure
        appPage.close unless appPage == nil
      end
    end

    def build  
      dirs = Dir.entries("../../apps").drop(2)
      dirs.each { |dir| 
        app = JSON.parse( IO.read('../../apps/'+dir+'/info.json'))
        @@apps.push(app)
      }

      puts "Apps Loaded: "+@@apps.length.to_s
      @@apps.each{ |app| 
       render(app)        
      }
      # render(@@apps[0])

    end
    def findApps      
      apps = []
      Find.find('../apps/') do |path|
        if path.include? "info.json"
          apps.push(path)
        end 
      end
      pp apps  
    end
end

x = AppBuilder.new
x.build