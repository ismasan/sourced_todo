# frozen_string_literal: true

module Pages
  class TodoListPage < Pages::Page
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
          h1 { @todo_list.name }
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
