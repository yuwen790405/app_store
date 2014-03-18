# Renders HTML page of all apps bas on
require 'pp'
require 'json'
require 'pry'
require 'fileutils'
require 'erubis'
require 'pathname'
require 'active_support/all'

class AppBuilder

  def self.build
    root = Pathname(__FILE__).expand_path.dirname
    apps_root = root + "../../apps/*/info.json"

    apps = Dir.glob(apps_root).map { |path| JSON.parse(File.read(path)) }

    live_apps = apps.find_all { |app| app["is_live"] }

    live_apps.each{ |app| render_app(root, app) }

    puts "Found #{live_apps.length} live apps out of #{apps.length} total"

    render_list(root, live_apps)
  end

  def self.render_app(root, app)
    FileUtils::mkdir_p(root + "site/pages")
    FileUtils::cd(root + "site/pages") do
      eruby = Erubis::Eruby.new(File.read(root + 'templates/page.erb'))
      File.open("#{app['name']}.html", 'w') do |f|
        f.puts eruby.result({
          :app_name         => app['name'],
          :app_title        => app['title'],
          :app_tags         => app['tags'],
          :app_version      => app['version'],
          :app_description  => app['description'],
          :app_parameters   => app['parameters']
        })
      end
    end
  end

  def self.render_list(root, apps)
    path = root + "site/pages"
    FileUtils::mkdir_p(path)
    FileUtils::cd(path) do
      eruby = Erubis::Eruby.new(File.read(root + 'templates/index.erb'))
      File.open("index.html", 'w') do |f|
        f.puts eruby.result({
          :apps => apps
        })
      end
    end
  end

end

AppBuilder.build