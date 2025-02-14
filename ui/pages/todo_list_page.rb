# frozen_string_literal: true

module Pages
  class TodoListPage < Pages::Page
    # react Todos::ListActor::System::Updated do |evt|
    #   todo_list = Todos::ListActor.load(evt.stream_id)
    #   ui.merge_fragments Pages::TodoListPage.new(
    #     todo_list: todo_list.state,
    #     events: todo_list.history,
    #   )
    # end

    class UpdateName < Phlex::HTML
      def initialize(todo_list)
        @todo_list = todo_list
      end

      def view_template
        Components::Command(
          Todos::ListActor::UpdateName, 
          stream_id: @todo_list.id,
        ) do |form|
          form.text_field(
            'name', 
            class: 'nice-input', 
            value: @todo_list.name,
          )
        end
      end
    end

    def initialize(todo_list:, events: [], seq: nil, layout: false, interactive: true)
      super(layout:)

      @todo_list = todo_list
      @events = events
      @seq = seq
      @interactive = interactive && @todo_list.active?
    end

    private

    def title = @todo_list.name
    def page_id = @todo_list.id

    def container
      div id: 'main' do
        div class: 'todo-list-header' do
          Components::InlineEdit(enabled: @interactive) do |edit|
            edit.trigger do
              h1(data: { 'edit-trigger' => true }) { @todo_list.name }
            end
            edit.target do
              render UpdateName.new(@todo_list)
            end
          end
          Components::StatusBadge(@todo_list.status)
          span(class: 'indicator', data: { show: '$fetching' }) { '...' }
        end

        Components::TodoList(todo_list: @todo_list, interactive: @interactive)
      end

      div id: 'sidebar' do
        Components::EventList(events: @events, seq: @seq, href_prefix: 'todo-lists')
      end
    end
  end
end
