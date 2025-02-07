module Pages
  class TodoListPage < Phlex::HTML
    def initialize(todo_list:, events: [])
      @todo_list = todo_list
      @events = events
    end

    def view_template
      Layouts::Layout(title: 'Todo List') do
        div class: 'container' do
          div id: 'main' do
            h1 do
              span { 'Todo List' }
              span(class: 'indicator', data: { show: '$fetching' }) { '...' }
            end

            Components::TodoList(todo_list: @todo_list)
          end

          div id: 'sidebar' do
            Components::EventList(events: @events)
          end
        end
      end
    end
  end
end
