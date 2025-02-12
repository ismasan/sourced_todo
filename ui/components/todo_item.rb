module Components
  class TodoItem < Phlex::HTML
    def initialize(todo, list_id, interactive: true)
      @todo = todo
      @list_id = list_id
      @interactive = interactive
    end

    def view_template
      edit = "_edit#{todo.id[0..7]}"

      li(
        class: [
          'todo-item',
          ('todo-item__done' if todo.done)
        ],
        data: { "signals-#{edit}" => 'false' },
        id: dom_id
      ) do
        Components::Action(Todos::ListActor[:toggle_item], stream_id: @list_id, payload: { id: todo.id }, on: :change) do |form|
          form.check_box('done', value: todo.done, checked: todo.done, disabled: !@interactive, class: 'todo-checkbox')
        end

        edit_field_id = dom_id('edit')

        div(class: 'todo-text-action', data: { show: "$#{edit}" }) do
          Components::Action(Todos::ListActor[:update_item_text], stream_id: @list_id, payload: { id: todo.id }) do |form|
            form.text_field('text', value: todo.text, id: edit_field_id, disabled: !@interactive)
          end
        end
        click = [%($#{edit} = true)]
        click << %(document.getElementById("#{edit_field_id}").focus())
        click = click.join(';')
        outside = %($#{edit} = false)
        data = @interactive ? { show: "!$#{edit}", 'on-click' => click, 'on-click__outside' => outside } : {}

        div(class: 'todo-text', data:) do
          plain todo.text
        end

        div(class: 'todo-services') do
          todo.services.each do |service|
            img(height: 24, src: "/images/services/#{service.downcase}.webp", class: 'todo-service')
          end
        end if todo.services.any?

        Components::Action(Todos::ListActor[:remove_item], stream_id: @list_id, attrs: { class: 'todo-delete' }, payload: { id: todo.id }) do |form|
          button { '✖' }
        end if @interactive
      end
    end

    private

    attr_reader :todo

    def dom_id(suffix = nil)
      ['todo', todo.id, suffix].compact.join('_')
    end
  end
end
