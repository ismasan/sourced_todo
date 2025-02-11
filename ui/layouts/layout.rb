require 'concurrent'

module Layouts
  class Layout < Phlex::HTML
    HASHED_ASSETS = Concurrent::Map.new

    def initialize(title:)
      @title = title
    end

    def view_template
      doctype

      html do
        head do
          meta(name: 'viewport', content: 'width=device-width, initial-scale=1.0')
          title { @title }
          link(rel: 'stylesheet', href: hashed_asset('/css/main.css'))
          script(type: 'module', src: 'https://cdn.jsdelivr.net/gh/starfederation/datastar@v1.0.0-beta.4/bundles/datastar.js')
        end

        onload = { 'on-load' => %(@get('#{url('/updates')}')) }
        body(data: onload.merge({ 'signals' => '{"fetching": false, "modal": false}' })) do
          yield
          div(id: 'modal', data: { show: '$modal' })
        end
      end
    end

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
