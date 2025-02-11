module Pages
  class TodoListPage < Phlex::HTML
    def initialize(todo_list:, events: [], seq: nil, layout: false, interactive: true)
      @todo_list = todo_list
      @events = events
      @seq = seq
      @layout = layout
      @interactive = interactive
    end

    def view_template
      if @layout
        Layouts::Layout(title: 'Todo List') do
          container
        end
      else
        container
      end
    end

    def container
      div id: 'container', class: 'container',
          data: { signals: JSON.generate(page: self.class.name, id: @todo_list.id) } do
        div id: 'main' do
          h1 do
            span { 'Todo List' }
            span(class: 'indicator', data: { show: '$fetching' }) { '...' }
          end

          Components::TodoList(todo_list: @todo_list, interactive: @interactive)
        end

        div id: 'sidebar' do
          Components::EventList(events: @events, seq: @seq, href_prefix: 'todo-lists')
        end
      end
    end
  end
end
