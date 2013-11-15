require 'rubygems'
require 'bundler'
Bundler.setup

$LOAD_PATH << File.dirname(__FILE__) + '/lib'
#require 'article'
#require 'indextank'

desc 'start a development server'
task :server do
  if which('shotgun')
    exec 'shotgun -O app.rb -p 9396'
  else
    warn 'warn: shotgun not installed; reloading is disabled.'
      exec 'ruby -rubygems app.rb -p 9396'
  end
end
def which(command)
  ENV['PATH'].
    split(':').
    map  { |p| "#{p}/#{command}" }.
    find { |p| File.executable?(p) }
end
task :start => :server

desc 'update the plugin file page'
task :plugins do
  require File.dirname(__FILE__) + '/scripts/plugin/update-html.rb'
end