module Components
  class TodoItem < Phlex::HTML
    def initialize(todo)
      @todo = todo
    end

    def view_template
      li(
        class: [
          'todo-item',
          ('todo-item__done' if todo.done),
        ],
        id: dom_id
      ) do
        Components::Action(Todos::ListActor[:toggle_item], payload: { id: todo.id }, on: :change) do |form|
          form.check_box('done', value: todo.done, checked: todo.done, class: 'todo-checkbox')
        end
        span(class: 'todo-text') { todo.text }
      end
    end

    private

    attr_reader :todo

    def dom_id = "todo-#{todo.id}"
  end
end
