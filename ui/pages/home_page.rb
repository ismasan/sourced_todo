module Pages
  class HomePage < Pages::Page
    def initialize(lists: [], layout: false)
      super(layout:)
      @active, @archived = lists.partition { |list| list[:status] == 'active' }
    end

    private

    def title = 'TODO lists'

    def container
      div id: 'main' do
        h1 { 'TODO lists' }
        if @active.any?
          h3 { 'Active' }
          Components::TodoLists(lists: @active)
        end

        if @archived.any?
          h3 { 'Archived' }
          Components::TodoLists(lists: @archived)
        end
      end

      div id: 'sidebar' do
        Components::Command(Todos::ListActor::Create) do |form|
          form.text_field('name', required: true, autocomplete: 'off', class: 'nice-input')
          button(class: 'nice-button', type: 'submit') { 'Create Todo List' }
        end
      end
    end
  end
end
