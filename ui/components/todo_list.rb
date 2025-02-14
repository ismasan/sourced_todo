module Components
  class TodoList < Phlex::HTML
    def initialize(todo_list:, interactive: true)
      @todo_list = todo_list
      @interactive = interactive
    end

    def view_template
      div id: "todo-list-#{@todo_list.id}", class: ['todo-list', ('paused' if @todo_list.paused)] do
        if @interactive
          Components::Command(
            Todos::ListActor::AddItem,
            stream_id: @todo_list.id,
            class: 'todo-form'
          ) do |form|
            form.text_field(
              'text',
              class: 'todo-input',
              placeholder: 'Add a new todo...',
              autocomplete: 'off',
              value: @todo_list.duplicated_item&.text
            )
            button(type: 'submit', class: 'todo-button') { 'Add' }
          end
          if @todo_list.duplicated_item
            p(class: 'paused-message') do
              plain 'An item with the same text already exists. Please correct the name.'
            end
          end
        elsif @todo_list.active?
          p { a(href: url("/todo-lists/#{@todo_list.id}")) { 'Back to list' } }
        end

        ul(class: 'todo-list') do
          @todo_list.items.each do |item|
            Components::TodoItem(
              item,
              @todo_list.id,
              duplicated_id: @todo_list.duplicated_item&.id,
              interactive: @interactive && !@todo_list.paused
            )
          end
        end
      end
    end
  end
end
