module Pages
  class TodoListPage < Phlex::HTML
    def initialize(todo_list:)
      @todo_list = todo_list
    end

    def view_template
      Layouts::Layout(title: 'Todo List') do
        h1 do
          span { 'Todo List' }
          span(class: 'indicator', data: { show: '$fetching' }) { '...' }
        end

        Components::TodoList(todo_list: @todo_list)
      end
    end
  end
end
