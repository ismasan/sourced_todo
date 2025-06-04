module Pages
  class Page < Phlex::HTML
    include Sourced::UI::Components::DatastarHelpers

    def initialize(layout: false)
      @layout = layout
    end

    def view_template
      if @layout
        Layouts::Layout(title:) do
          wrapper
        end
      else
        wrapper
      end
    end

    private

    def title = 'Page'
    def page_id = self.class.name

    def wrapper
      div(
        id: 'container', 
        class: 'container',
          data: { signals: JSON.generate(page_signals) }
      ) do
        container
      end
    end

    def container
      h1 { title }
    end

    def page_signals
      { page_key: self.class.name, page_id: }
    end
  end
end
