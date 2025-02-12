module Pages
  class HomePage < Pages::Page
    def initialize(lists: [], layout: false)
      super(layout:)
      @lists = lists
    end

    private

    def title = 'TODO lists'

    def container
      div id: 'main' do
        h1 { 'TODO lists' }
        table(class: 'table') do
          tr do
            th { 'Name' }
            th { 'Progress' }
            th { 'Members' }
            th { 'Updated at' }
          end

          @lists.each do |list|
            tr do
              td { a(href: url("/todo-lists/#{list[:id]}")) { list[:name] } }
              td do
                progress(max: list[:item_count], value: list[:done_count], class: 'progress')
              end
              td { list[:members].join(', ') }
              td { list[:updated_at] }
            end
          end
        end
      end

      div id: 'sidebar' do
        Components::Action(Todos::ListActor::Create) do |form|
          form.text_field('name', required: true, autocomplete: 'off', class: 'nice-input')
          button(class: 'nice-button', type: 'submit') { 'Create Todo List' }
        end
      end
    end
  end
end
