module Layouts
  class Login < Layouts::Base
    def view_template(&block)
      doctype

      html do
        head do
          meta(name: 'viewport', content: 'width=device-width, initial-scale=1.0')
          title { @title }
          link(rel: 'stylesheet', href: hashed_asset('/css/main.css'))
        end

        body(&block)
      end
    end
  end
end
