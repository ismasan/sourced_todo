module Components
  class TodoList < Component
    class AddItem < Phlex::HTML
      def initialize(todo_list)
        @todo_list = todo_list
      end

      def view_template
        Sourced::UI::Components::Command(
          Todos::List::AddItem, 
          stream_id: @todo_list.id, 
          id: 'new-item-form',
          class: 'todo-form'
        ) do |form|
          form.text_field(
            'text',
            class: 'todo-input',
            placeholder: 'Add a new todo...',
            autocomplete: 'off'
          )
          button(type: 'submit', class: 'todo-button') { 'Add' }
        end
      end
    end

    def initialize(todo_list:, interactive: true)
      @todo_list = todo_list
      @interactive = interactive
    end

    def view_template
      return deleted_message if @todo_list.deleted?

      div id: "todo-list-#{@todo_list.id}", class: ['todo-list', ('paused' if @todo_list.paused)] do
        if @interactive
          render AddItem.new(@todo_list)
          if @todo_list.duplicated_item
            p(class: 'paused-message') do
              plain 'An item with the same text already exists. Please correct the name.'
            end
          end
        elsif @todo_list.active?
          p { a(href: url("/todo-lists/#{@todo_list.id}")) { 'Back to list' } }
        end

        sortable_data = _d.on['reordered']
                .run(%($from = event.detail.from; $to = event.detail.to;))
                .post("/commands/#{@todo_list.id}/reorder-items")
                .signals(from: nil, to: nil)
                .to_h
                .merge(sortable: true)

        ul(class: 'todo-list', data: sortable_data) do
          @todo_list.items.each do |item|
            Components::TodoItem(
              item,
              @todo_list.id,
              duplicated_id: @todo_list.duplicated_item&.id,
              interactive: @interactive
            )
          end
        end
      end
    end

    def deleted_message
      div id: "todo-list-#{@todo_list.id}", class: %w[todo-list deleted] do
        h2 { 'This list has been deleted' }
      end
    end
  end
end
