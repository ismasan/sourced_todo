require 'rack/unreloader'
require_relative 'boot'
require_relative 'app'

Unreloader = Rack::Unreloader.new(subclasses: %w[Sinatra::Base]) { App }
Unreloader.require './app.rb'
Dir['./ui/**/*.rb'].each { |file| Unreloader.require file }

use Rack::Static, urls: ['/assets', '/js'], root: 'public'
run Unreloader
