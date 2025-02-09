module Components
  class Modal < Phlex::HTML
    def initialize(title: 'Modal dialog', content: nil, buttons: true)
      @title = title
      @content = content
      @buttons = buttons
    end

    def view_template
      div(id: 'modal', data: { show: '$modal' }) do
        div(class: 'modal-underlay', data: { 'on-click' => '$modal = false' })
        div(class: 'modal-content') do
          h1 { @title }
          if @content
            div(class: 'modal-body') do
              render @content
            end
          end
          if @buttons
            br
            whitespace
            button(class: 'btn danger', data: { 'on-click' => '$modal = false' }) do
              'Close'
            end
          end
        end
      end
    end
  end
end
