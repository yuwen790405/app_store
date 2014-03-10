# Renders HTML page of all apps bas on 
require 'rubygems' 
# require 'bundler/setup' 
require 'pp'
require 'json'
require 'find'
require 'pry'

class AppBuilder
    
    @@apps = []
    @@apps_loaded = 0

    def renderIndex(apps)
      @apps = apps
      begin
        if File.directory?('./pages')
          header = IO.read('./templates/header.html')
          footer = IO.read('./templates/footer.html')
          page = File.open("./pages/index.html", "w+")            
          page.puts header
          page.puts '<div class="hero-unit">'
          page.puts '<h1>Ruby App Executors</h1><p>Packable apps to extend the functionality of your Good Data project or <a href="#"> build your own.</a></p>'
          page.puts '</div>'
          page.puts '<div align="center" class="container"><ul class="thumbnails">'
          @apps.each do |app|
            app_name = app['name'].split('_').map(&:capitalize).join(' ')
            app_url = app['name']+'.html'
            page.puts "<li class=\"span4\"><a class=\"thumbnail\" href=\"#{app_url}\"><h4>#{app_name}</h4>"
            page.puts "<p>#{app['description']}</p>"
            page.puts "<small><div style=\"align:right\">#{app['author']['name']} | <cite title=\"#{app['version']}\">#{app['version']}</cite></div></small>"
            page.puts "</a></li>"
          end          
          page.puts '</ul></div>'
          page.puts footer

        else
          Dir.mkdir('pages')
          renderIndex(@apps)
        end
      rescue IOError => e
      ensure
        page.close unless page == nil
      end
    end

    def renderApp(app_page)
      @app_page = app_page
      @app_name = app_page['name']
      @app_version = app_page['version']
      @app_category = app_page['category']
      @app_language = app_page['language']
      @app_tags = app_page['tags']
      @app_description = app_page['description']
      @parameters = app_page['parameters']

      begin
        if File.directory?('./pages')
          header = IO.read('./templates/header.html')
          footer = IO.read('./templates/footer.html')
          page = File.open("./pages/"+@app_name+".html", "w+")            
          page.puts header
          page.puts '<div align="center" class="container">'
          page.puts '<p align="center" class="small"> <kbd>Version '+@app_version+'</kbd></p>'
          page.puts '<h1 class="cover-heading">'+@app_name.split('_').map(&:capitalize).join(' ')+'</h1>'
          page.puts '<p class="lead">'+@app_page["tags"]+'.</p>'
          page.puts "<h3>Description</h3>"
          page.puts '<p align="center">'+@app_description+'</p>'
          page.puts "<h3>Parameters</h3>"
          page.puts '<table id="details" style="width:500px;" align="center" class="table table-condensed">'
          page.puts '<tr><td align="left">Name</td><td align="left">Description</td><td>Mandatory</td></tr>'
          @parameters.each do |param|
            page.puts '<tr><td align="left">'+param["name"]+'</td><td align="left">'+param["description"]+'</td><td>' + (param["mandatory"] || false).to_s + '</td></tr>'
          end          
          page.puts '</table>'
          page.puts '<p class="lead">Run instructions</p>'
          page.puts '<pre>'
          page.puts 'cd app_store/apps'
          page.puts "bin/gooddata -Ulogin -Ppass -p PROJECT_PID run_ruby --dir #{@app_name}/ --params #{@app_name}/params.json  --name \"Download objects execution\" --remote"
          page.puts '</pre>'
          page.puts '<p class="lead">'+@app_name+'</p>' 
          page.puts '<a href="'+@app_name+'" class="btn btn-lg btn-default">Install</a></div>'
          page.puts '</div'
          page.puts footer
          @@apps_loaded += 1 
        else
          Dir.mkdir('pages')
          renderApp(@app_page)
        end
      rescue IOError => e
      ensure
        page.close unless page == nil
      end
    end

    def build 
      Dir.glob("../../apps/*/info.json") do |path| 
        app = JSON.parse( File.read(path))
        if app['is_live']
          @@apps << app
        end
      end
      puts "Apps Found: #{@@apps.length}"
      @@apps.each{ |app|         
        renderApp(app)
        puts "=> App Published: #{app['name']}"
      }
      renderIndex(@@apps)
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