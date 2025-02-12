module Components
  class EventsTree < Phlex::HTML
    Node = Struct.new(:parent, :children)

    def initialize(events: [], highlighted: nil, href_prefix: 'carts')
      @events = build_tree(events)
      @highlighted = highlighted
      @href_prefix = href_prefix
    end

    private def build_tree(events)
      # Create a lookup hash for quick access to events by ID
      node_map = events.each_with_object({}) { |event, map| map[event.id] = Node.new(event, []) }

      # Track root events (those without parents)
      root_nodes = []

      # Build parent-child relationships
      node_map.values.each do |node|
        if node.parent.causation_id == node.parent.id
          # This is a root event
          root_nodes << node
        else
          # Find parent and add this event as its child
          parent = node_map[node.parent.causation_id]
          parent.children << node if parent
        end
      end

      root_nodes
    end

    def view_template
      div(class: 'events-timeline') do
        button(class: 'toggle-payloads', data: { on: { click: '$showPayloads = !$showPayloads' } }) do
          span(data: { text: '$showPayloads ? "Hide Payloads" : "Show Payloads"' })
        end
        ul(class: 'tree tree-view') do
          @events.each do |node|
            render_node(node)
          end
        end
      end
    end

    def render_node(node)
      li do
        event = node.parent
        MessageRow(
          event,
          href: nil,
          highlighted: @highlighted == event.id
        )

        if node.children.any?
          ul do
            node.children.each do |child|
              render_node(child)
            end
          end
        end
      end
    end

    def producer_for(event)
      code { "[#{event.metadata[:producer]}] " } if event.metadata[:producer]
    end

    private def is_command?(event)
      event.id == event.causation_id
    end
  end
end
