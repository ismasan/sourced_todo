module Layouts
  class Layout < Layouts::Base
    def initialize(title:, sse: '/updates')
      super(title: title)
      @sse = sse
    end

    def view_template
      doctype

      html do
        head do
          meta(name: 'viewport', content: 'width=device-width, initial-scale=1.0')
          title { @title }
          link(rel: 'stylesheet', href: hashed_asset('/css/main.css'))
          script(type: 'module', src: 'https://cdn.jsdelivr.net/gh/starfederation/datastar@v1.0.0-beta.6/bundles/datastar.js')
        end

        body(data: { 'signals' => '{"fetching": false, "modal": false}' }) do
          div class: 'nav' do
            div class: 'link-group' do
              a(href: '/') { 'Todo lists' }
              a(href: '/sourced') { 'System' }
            end
            div class: 'link-group' do
              span { "logged in as #{helpers.current_user.username}" }
              a(class: 'logout', href: '/logout') { 'Logout' }
            end
          end

          yield
          div(id: 'modal', data: { show: '$modal' })
          onload = { 'on-load' => %(@get('#{url(@sse)}')) }
          # onload needs to be at the end
          # to make sure to collect all signals on the page
          div(data: onload)
          script(type: 'module', src: 'https://cdn.jsdelivr.net/npm/sortablejs@1.15.3')
          script do
            raw safe <<~JAVASCRIPT
              document.addEventListener('DOMContentLoaded', function() {
                document.querySelectorAll('[data-sortable]').forEach(function(sortContainer) {
                  new Sortable(sortContainer, {
                      animation: 150,
                      ghostClass: 'opacity-25',
                      onEnd: (evt) => {
                      const cevent = new CustomEvent('reordered', {detail: {from: evt.oldIndex, to: evt.newIndex}})
                        sortContainer.dispatchEvent(cevent);
                      }
                  })
                })
              })
            JAVASCRIPT
          end
        end
      end
    end
  end
end
