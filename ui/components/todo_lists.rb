module Components
  class TodoLists < Phlex::HTML
    class ArchiveList < Phlex::HTML
      def initialize(list_id)
        @list_id = list_id
      end

      def view_template
        Components::Command(Todos::ListActor::Archive, stream_id: @list_id) do |_form|
          button(type: 'submit') { 'Archive' }
        end
      end
    end

    class DeleteList < Phlex::HTML
      def initialize(list_id)
        @list_id = list_id
      end

      def view_template
        Components::Command(Todos::ListActor::Delete, stream_id: @list_id) do |_form|
          button(type: 'submit') { 'Delete' }
        end
      end
    end

    def initialize(lists: [])
      @lists = lists
    end

    def view_template
      table(class: 'table') do
        tr do
          th(class: 'name-row') { 'Name' }
          th(class: 'progress-row') { 'Progress' }
          th(class: 'members-row') { 'Members' }
          th(class: 'date-row') { 'Updated at' }
          th(class: 'status-row') { 'Status' }
          th(class: 'tools-row') { '' }
        end

        @lists.each do |list|
          tr do
            td { a(href: url("/todo-lists/#{list[:id]}")) { list[:name] } }
            td do
              progress(max: list[:item_count], value: list[:done_count], class: 'progress')
            end
            td { list[:members].join(', ') }
            td { small { list[:updated_at] } }
            td { Components::StatusBadge(list[:status]) }
            td do
              if list[:status] == 'active'
                render ArchiveList.new(list[:id])
              elsif list[:status] == 'archived'
                render DeleteList.new(list[:id])
              end
            end
          end
        end
      end
    end
  end
end
