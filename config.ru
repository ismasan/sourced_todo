require 'rack/unreloader'
require 'sourced/ui/dashboard'
require_relative 'boot'
require_relative 'app'

Unreloader = Rack::Unreloader.new(subclasses: %w[Sinatra::Base]) { App }
Unreloader.require './app.rb'
Dir['./ui/**/*.rb'].each { |file| Unreloader.require file }

Sourced::UI::Dashboard.configure do |config|
  config.header_links([
    { label: 'back to TODO app', href: '/', url: false }
  ])
end

map '/sourced' do
  run Sourced::UI::Dashboard
end

map '/' do
  use Rack::Static, urls: ['/assets', '/js'], root: 'public'
  run Unreloader
end
