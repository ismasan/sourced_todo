module Components
  class EventList < Phlex::HTML
    def initialize(events:, href_prefix: 'events', reverse: true)
      @events = events
      @events = @events.reverse if reverse
      @href_prefix = href_prefix
    end

    def view_template
      div id: 'event-list' do
        h2 { 'History' }
        if @events.any?
          p(data: { signals: '{"showPayloads": false}' }) do
            button(class: 'toggle-payloads', data: { on: { click: '$showPayloads = !$showPayloads' } }) do
              span(data: { text: '$showPayloads ? "Hide Payloads" : "Show Payloads"' })
            end
          end
        end
        div class: 'list' do
          @events.each do |event|
            MessageRow(event, href: url("/#{@href_prefix}/#{event.stream_id}"))
          end
        end
      end
    end
  end
end
