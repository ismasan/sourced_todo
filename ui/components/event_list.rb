module Components
  class EventList < Component
    def initialize(events:, seq: nil, href_prefix: 'todo-lists', reverse: true)
      @events = events
      @first_seq = @events.first&.seq
      @last_seq = @events.last&.seq
      @events = @events.reverse if reverse
      @seq = seq || @last_seq
      @href_prefix = href_prefix
    end

    def view_template
      div id: 'event-list' do
        div class: 'header' do
          h2 { 'History' }
          if @events.any?
            div(class: 'history-tools', data: _d.signals(showPayloads: false).to_h) do
              disabled_back = @first_seq == @seq
              disabled_forward = @last_seq == @seq

              span(class: 'pagination') do
                button(disabled: disabled_back,
                  data: _d.on.click.get("/#{@href_prefix}/#{@events.first.stream_id}/#{@seq - 1}").to_h) do
                  '←'
                end
                button(disabled: disabled_forward,
                  data: _d.on.click.get("/#{@href_prefix}/#{@events.first.stream_id}/#{@seq + 1}").to_h) do
                  '→'
                end
                small { "current version: #{@seq} " }
              end

              div(class: 'switches') do
                button(class: 'toggle-payloads', data: _d.on.click.run('$showPayloads = !$showPayloads').to_h) do
                  span(data: { text: '$showPayloads ? "Hide Payloads" : "Show Payloads"' })
                end
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
