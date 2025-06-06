module Pages
  class HomePage < Pages::Page

    # React to initial page load
    # react 'GET /todo-lists' do |evt|
    #   lists = Listings.all
    #   ui.render Pages::HomePage.new(lists:)
    # end
    #
    # # React to async event
    # react Listings::System::Updated do |evt|
    #   lists = Listings.all
    #   ui.merge_fragments Pages::HomePage.new(lists:)
    # end

    class CreateList < Phlex::HTML
      def view_template
        Sourced::UI::Components::Command(Todos::List::Create, class: 'nice-form') do |form|
          form.text_field('name', required: true, autocomplete: 'off', class: 'nice-input')
          button(class: 'nice-button', type: 'submit') { 'Create Todo List' }
        end
      end
    end

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
        render CreateList.new
      end
    end
  end
end
