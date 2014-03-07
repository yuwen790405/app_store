# Renders HTML page of all apps bas on 
require 'rubygems' 
require 'bundler/setup' 
require 'pp'
require 'json'
require 'find'

class AppBuilder
    
    @@apps = []

    def render(app_page)
      @app_page = app_page
      @app_name = app_page['name']

      begin
        if File.directory?('./pages')
          header = IO.read('./templates/header.html')
          footer = IO.read('./templates/footer.html')
          appPage = File.open("./pages/"+@app_name+".html", "w+")            
          appPage.puts header
          appPage.puts '<h1 class="cover-heading">'+@app_name+'</h1>'
          appPage.puts '<p class="lead">'+@app_name+'</p>' #description
          appPage.puts '<p class="lead">'+@app_name+'</p>' #more text
          appPage.puts '<a href="'+@app_name+'" class="btn btn-lg btn-default">Install</a></div>' # uri or rel API call. 
          appPage.puts "<TABLE BORDER='1' ALIGN='center'>"
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
        puts app['name']
      }

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