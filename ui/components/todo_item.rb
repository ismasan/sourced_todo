module Components
  class TodoItem < Phlex::HTML
    def initialize(todo, interactive: true)
      @todo = todo
      @interactive = interactive
    end

    def view_template
      edit = "edit#{todo.id[0..7]}"

      li(
        class: [
          'todo-item',
          ('todo-item__done' if todo.done)
        ],
        data: { "signals-#{edit}" => 'false' },
        id: dom_id
      ) do
        Components::Action(Todos::ListActor[:toggle_item], payload: { id: todo.id }, on: :change) do |form|
          form.check_box('done', value: todo.done, checked: todo.done, disabled: !@interactive, class: 'todo-checkbox')
        end

        edit_field_id = dom_id('edit')

        div(class: 'todo-text-action', data: { show: "$#{edit}" }) do
          Components::Action(Todos::ListActor[:update_item_text], payload: { id: todo.id }) do |form|
            form.text_field('text', value: todo.text, id: edit_field_id, disabled: !@interactive)
            button(type: 'button', data: { 'on-click' => %($#{edit} = false) }) { 'cancel' }
          end
        end
        click = [%($#{edit} = true)]
        click << %(document.getElementById("#{edit_field_id}").focus())
        click = click.join(';')
        data = @interactive ? { show: "!$#{edit}", 'on-click' => click } : {}

        span(class: 'todo-text', data:) do
          todo.text
        end
      end
    end

    private

    attr_reader :todo

    def dom_id(suffix = nil)
      ['todo', todo.id, suffix].compact.join('_')
    end
  end
end
