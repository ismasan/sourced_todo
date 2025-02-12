module Components
  class TodoList < Phlex::HTML
    def initialize(todo_list:, interactive: true)
      @todo_list = todo_list
      @interactive = interactive
    end

    def view_template
      div id: "todo-list-#{@todo_list.id}", class: 'todo-list' do
        if @interactive
          Components::Action(Todos::ListActor[:add_item], stream_id: @todo_list.id,
                                                          attrs: { class: 'todo-form' }) do |form|
            form.text_field(
              'text',
              class: 'todo-input',
              placeholder: 'Add a new todo...',
              required: true
            )
            button(type: 'submit', class: 'todo-button') { 'Add' }
          end
        else
          p { a(href: url("/todo-lists/#{@todo_list.id}")) { 'Back to list' } }
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
            Components::TodoItem(item, @todo_list.id, interactive: @interactive)
          end
        end
      end
    end
  end
end
