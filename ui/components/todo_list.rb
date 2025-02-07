module Components
  class TodoList < Phlex::HTML
    def initialize(todo_list:)
      @todo_list = todo_list
    end

    def view_template
      div id: 'todo-list' do
        Components::Action(Todos::ListActor[:add_item], attrs: { class: 'todo-form' }) do |form|
          form.text_field(
            'text',
            class: 'todo-input',
            placeholder: 'Add a new todo...',
            required: true
          )
          button(type: 'submit', class: 'todo-button') { 'Add' }
        end

        div(class: 'filters') do
          input(type: 'radio', name: 'filter', id: 'filter-all', checked: 'checked')
          label(for: 'filter-all') { 'All' }
          input(type: 'radio', name: 'filter', id: 'filter-open')
          label(for: 'filter-open') { 'Open' }
          input(type: 'radio', name: 'filter', id: 'filter-done')
          label(for: 'filter-done') { 'Done' }
        end

        ul(class: 'todo-list') do
          @todo_list.items.each do |item|
            Components::TodoItem(item)
          end
        end
      end
    end
  end
end
