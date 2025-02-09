module Components
  class EventList < Phlex::HTML
    def initialize(events:, seq: nil, href_prefix: 'todo-lists', reverse: true)
      @events = events
      @events = @events.reverse if reverse
      @seq = seq
      @href_prefix = href_prefix
    end

    def view_template
      div id: 'event-list' do
        div class: 'header' do
          h2 { 'History' }
          if @events.any?
            p(data: { signals: '{"showPayloads": false}' }) do
              button(class: 'toggle-payloads', data: { on: { click: '$showPayloads = !$showPayloads' } }) do
                span(data: { text: '$showPayloads ? "Hide Payloads" : "Show Payloads"' })
              end
            end
          end
        end
        div class: 'list' do
          @events.each do |event|
            MessageRow(
              event,
              highlighted: (event.seq == @seq),
              href: url("/#{@href_prefix}/#{event.stream_id}/#{event.seq}")
            )
          end
        end
      end
    end
  end
end
