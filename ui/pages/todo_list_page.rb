module Pages
  class TodoListPage < Pages::Page
    def initialize(todo_list:, events: [], seq: nil, layout: false, interactive: true)
      super(layout:)

      @todo_list = todo_list
      @events = events
      @seq = seq
      @interactive = interactive
    end

    private

    def title = @todo_list.name
    def page_id = @todo_list.id

    def container
      div id: 'main' do
        h1 do
          span { @todo_list.name }
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
