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
          div class: 'editable-name', data: { signals: '{"_editing": false}', 'on-click__outside' => '$_editing = false' } do
            h1(data: { 'on-click' => '$_editing = true', show: '!$_editing' }) { @todo_list.name }
            Components::Command(
              Todos::ListActor::UpdateName, 
              stream_id: @todo_list.id,
              attrs: { data: { show: '$_editing' } }
            ) do |form|
              form.text_field(
                'name', 
                class: 'nice-input', 
                value: @todo_list.name,
              )
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
