module Components
  class TodoItem < Phlex::HTML
    def initialize(todo, list_id, interactive: true, duplicated_id: nil)
      @todo = todo
      @list_id = list_id
      @interactive = interactive
      @duplicated_id = duplicated_id
    end

    def view_template
      li(
        class: [
          'todo-item',
          ('todo-item__done' if todo.done),
          ('todo-item__duplicated' if todo.id == @duplicated_id)
        ],
        id: dom_id
      ) do
        Components::Command(Todos::List[:toggle_item], stream_id: @list_id, on: :change) do |form|
          form.payload_fields id: todo.id
          form.check_box('done', value: todo.done, checked: todo.done, disabled: !@interactive, class: 'todo-checkbox')
        end

        div(class: 'todo-text-action') do
          Components::InlineEdit(enabled: @interactive) do |edit|
            edit.trigger do
              div(class: 'todo-text') do
                plain todo.text
              end
            end

            edit.target do
              Components::Command(
                Todos::List[:update_item_text],
                stream_id: @list_id,
                class: 'hidden'
              ) do |form|
                form.payload_fields id: todo.id
                form.text_field('text', value: todo.text, disabled: !@interactive)
              end
            end
          end
        end

        if todo.services.any?
          div(class: 'todo-services') do
            todo.services.each do |service|
              img(height: 24, src: "/images/services/#{service.downcase}.webp", class: 'todo-service')
            end
          end
        end

        if @interactive
          Components::Command(Todos::List[:remove_item], stream_id: @list_id, class: 'todo-delete') do |form|
            form.payload_fields id: todo.id
            button { '✖' }
          end
        end
      end
    end

    private

    attr_reader :todo

    def dom_id(suffix = nil)
      ['todo', todo.id[0..5], suffix].compact.join('_')
    end
  end
end
