# frozen_string_literal: true

require 'zeitwerk'
require 'phlex-sinatra'
require 'sourced'
require 'sequel'
require 'dotenv'
Dotenv.load '.env'

# Setup infrastructure
CODE_LOADER = Zeitwerk::Loader.new

CODE_LOADER.push_dir("#{__dir__}/ui")
CODE_LOADER.push_dir("#{__dir__}/domains")
CODE_LOADER.push_dir("#{__dir__}/lib")
CODE_LOADER.setup

$LOAD_PATH.unshift File.dirname(__FILE__)

# Fix Phlex 2.0.0.rc1 to work with Phlex::Sinatra
module Phlex
  class SGML
    def helpers = @_context.view_context
  end
end

DATABASE_URL = ENV.fetch('DOCKER_DATABASE_URL') {ENV.fetch('DATABASE_URL')}

puts "DATABASE_URL #{DATABASE_URL}"

# Configure Sourced
Sourced.configure do |config|
  config.backend = Sequel.connect(DATABASE_URL)
end

Sourced.config.backend.install # unless Sourced.config.backend.installed?

# Register Sourced deciders and reactors
Sourced.register(Todos::List)
Sourced.register(Todos::SlackDispatcher) if ENV['SLACK_WEBHOOK_URL']
Sourced.register(Todos::Listings)

Zeitwerk::Loader.eager_load_all if ENV['RACK_ENV'] == 'production'
