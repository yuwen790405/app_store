#! /usr/bin/env ruby

require 'bundler/cli'
require 'fileutils'

# Re
require_relative 'core'

# SCRIPT_PARAMS (so called) wrapper
$SCRIPT_PARAMS ||= {}

FETCH_GEMS = $SCRIPT_PARAMS['FETCH_GEMS'] || true

# Gems to download
if FETCH_GEMS
  repo_gem = 'https://gdc-ms-grache.s3.amazonaws.com/grache-core.zip'
  # repo_gem = 'https://github.com/korczis/grache/archive/master.zip'

  cmd = "curl -LOk --retry 3 #{repo_gem} 2>&1"
  puts cmd
  system(cmd)

  repo_gem_file = repo_gem.split('/').last

  cmd = "unzip -o #{repo_gem_file} 2>&1"
  puts cmd
  system(cmd)

  FileUtils.rm repo_gem_file
end

grash('cp -a grache/lib/* .')

# Load grache
require_relative 'grache'

# Print grache version (kind of check(
puts "Grache::VERSION = #{Grache::VERSION}"

# Fetch grache pack
Grache::Packer.new.install()

# Invoke bundler
Bundler::CLI.new.invoke(:install, [], :gemfile => 'Gemfile.Generated', :local => true, :deployment => true, :verbose => true, :binstubs => './bin')
# require 'bundler/setup'

# Show bundle config
grash('cat .bundle/config')

# Show installed gems
Bundler::CLI.new.invoke(:show, [], :verbose => true)

# Finally call main execution script
require_relative './main.rb'