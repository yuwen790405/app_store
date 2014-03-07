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
      @app_version = app_page['version']
      @app_category = app_page['category']
      @app_language = app_page['language']
      @app_tags = app_page['tags']
      @app_token = app_page['parameters'][0]['name']
      @app_token_description = app_page['parameters'][0]['description']
      @app_uri = app_page['parameters'][1]['name']
      @app_uri_description = app_page['parameters'][1]['description']
      @app_spec = app_page['parameters'][2]['name']
      @app_spec_description = app_page['parameters'][2]['description']

      begin
        if File.directory?('./pages')
          header = IO.read('./templates/header.html')
          footer = IO.read('./templates/footer.html')
          appPage = File.open("./pages/"+@app_name+".html", "w+")            
          appPage.puts header
          appPage.puts '<p align="center" class="small"> <kbd>Version '+@app_version+'</kbd></p>'
          appPage.puts '<h1 class="cover-heading">'+@app_name.split('_').map(&:capitalize).join(' ')+'</h1>'
          appPage.puts '<p class="lead">'+@app_category.split('_').map(&:capitalize).join(' ')+', built lovingly in '+@app_language.capitalize+'.</p>' #description
          appPage.puts '<table id="details" style="width:500px;" align="center" class="table table-condensed">'
          appPage.puts '<tr><td align="left">'+@app_token.split('_').map(&:capitalize).join(' ')+'</td><td align="left">'+@app_token_description+'</td></tr>'
          appPage.puts '<tr><td align="left">'+@app_uri.split('_').map(&:capitalize).join(' ')+'</td><td align="left">'+@app_uri_description+'</td></tr>'
          appPage.puts '<tr><td align="left">'+@app_spec.split('_').map(&:capitalize).join(' ')+'</td><td align="left">'+@app_spec_description+'</td></tr>'
          appPage.puts '</table>'
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

      #@@apps.each{ |app| 
      #  render(app)
        
      #}
      render(@@apps[0])

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