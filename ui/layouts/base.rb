require 'concurrent'

module Layouts
  class Base < Phlex::HTML
    include Sourced::UI::Components::DatastarHelpers

    HASHED_ASSETS = Concurrent::Map.new

    def initialize(title:)
      @title = title
    end

    private

    if ENV['RACK_ENV'] == 'production'
      def hashed_asset(path)
        HASHED_ASSETS.fetch_or_store(path) do
          # Compute an MD5 hash of file contents at public/
          hash = Digest::MD5.file("public#{path}").hexdigest
          "#{path}?#{hash}"
        end
      end
    else
      def hashed_asset(path)
        "#{path}?#{Time.now.to_i}"
      end
    end
  end
end
