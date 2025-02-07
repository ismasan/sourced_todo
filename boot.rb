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

# Configure Sourced
Sourced.configure do |config|
  config.backend = Sequel.connect(ENV.fetch('DATABASE_URL'))
end

Sourced.config.backend.install # unless Sourced.config.backend.installed?

# Register Sourced deciders and reactors
Sourced.register(Todos::ListActor)
# Sourced.register(Carts::Listings)
# Sourced.register(Carts::Webhooks)
# Sourced.register(Inventory::Processor)
# Sourced.register(Leads::Lead)
# Sourced.register(Leads::Listings)
# Sourced.register(Leads::Webhooks::Dispatcher)

Zeitwerk::Loader.eager_load_all if ENV['RACK_ENV'] == 'production'
