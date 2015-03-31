#! /usr/bin/env ruby

$GEM_HOME = ENV['GEM_HOME']
$GEM_PATH = ENV['GEM_PATH']
$BASH_CMD = `which bash`.strip
$CURL_CMD = `which curl`.strip
$BUNDLER_CMD = `which bundler`.strip
$JAVA_CMD = `which java`.strip
$JRUBY_CMD = '/usr/share/java/executor-wrapper/jruby-complete-1.7.12.jar'

$RUBY_CMD = `which ruby`.strip
if $RUBY_CMD.empty?
  $RUBY_CMD = "#{$JAVA_CMD} -jar #{$JRUBY_CMD}"
end

$GEM_CMD = `which gem`.strip
if $GEM_CMD.empty?
  $GEM_CMD = "#{$RUBY_CMD} -S gem"
end

def grash(*args)
  cmd = "#{$BASH_CMD} -c \"#{args.join}\""
  puts "grash '#{cmd}'"
  res = system(cmd)
  # puts "RES: #{res}"
end

def grul(*args)
  cmd = "#{$CURL_CMD} #{args.join}"
  puts "grul '#{cmd}'"
  res = grash(cmd)
  # puts "RES: #{res}"
end

def grem(*args)
  # cmd = "GEM_HOME=#{$GEM_HOME} GEM_PATH=#{$GEM_PATH} #{$GEM_CMD} --debug #{args.join}"
  cmd = "#{$GEM_CMD} --debug #{args.join}"
  puts "grem '#{cmd}'"
  res = grash(cmd)
  # puts "RES: #{res}"
end

def grundler(*args)
  cmd = "#{$BUNDLER_CMD} #{args.join}"
  puts "grundler '#{cmd}'"
  res = grash(cmd)
  # puts "RES: #{res}"
end

def grexec(*args)
  cmd = "#{$BASH_CMD} #{args.join}"
  puts "grexec '#{cmd}'"
  res = system(cmd)
  # puts "RES: #{res}"
end

def grava(*args)
  cmd = "#{$JAVA_CMD} #{args.join}"
  puts "grava '#{cmd}'"
  res = grash(cmd)
  # puts "RES: #{res}"
end

def gruby(*args)
  cmd = "#{$RUBY_CMD} #{args.join}"
  puts "gruby '#{cmd}'"
  res = grash(cmd)
  # puts "RES: #{res}"
end