require 'rubygems'
require 'sinatra'
require 'sinatra/assetpack'
require 'redis'

configure :production do
  ENV['APP_ROOT'] ||= File.dirname(__FILE__)
end

ENV["REDISTOGO_URL"] ||= 'redis://localhost:6379' # development
REDIS_URI = URI.parse(ENV["REDISTOGO_URL"])
REDIS = Redis.new(:host => REDIS_URI.host, :port => REDIS_URI.port, :password => REDIS_URI.password)

set :app_file, __FILE__
set :static_cache_control, [:public, :max_age => 3600*24]

get '/' do
  erb :index
end

get '/plugin/' do
  @plugin_descriptions = REDIS.get('plugin.html')
  erb :plugin, :layout => false
end

get '/doc/' do
  redirect 'http://docs.fluentd.org'
end

set :root, File.dirname(__FILE__)
Sinatra.register Sinatra::AssetPack
assets {
  serve '/js',  from: 'app/js'  # Optional
  serve '/css', from: 'app/css' # Optional
  serve '/plugin/css', from: 'app/plugin/css'
  js :app, '/js/app.js', [
    '/js/*.js'
  ]
  css :application, '/css/application.css', [
    '/css/*.css'
  ]
  css :plugin, '/css/plugin.css', [
    '/plugin/css/*.css'
  ]
  js_compression :yui
  css_compression :yui
  prebuild true # only on production
  expires 24*3600*7, :public
}
