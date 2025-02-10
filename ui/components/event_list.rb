module Components
  class EventList < Phlex::HTML
    def initialize(events:, seq: nil, href_prefix: 'todo-lists', reverse: true, show_commands: true)
      @events = events
      @show_commands = show_commands
      @events = @events.select { |e| e.is_a?(Sourced::Event) } unless show_commands
      @first_seq = @events.first&.seq
      @last_seq = @events.last&.seq
      @events = @events.reverse if reverse
      @seq = seq || @last_seq
      @href_prefix = href_prefix
      @current_index = seq ? @events.index { |e| e.seq == @seq } : 0
    end

    def view_template
      div id: 'event-list' do
        div class: 'header' do
          h2 { 'History' }
          if @events.any?
            div(class: 'history-tools', data: { signals: '{"showPayloads": false}' }) do
              disabled_forward = @current_index.zero?
              disabled_back = @current_index == @events.size - 1

              span(class: 'pagination') do
                button(disabled: disabled_back,
                       data: { on: { click: %(@get('/#{@href_prefix}/#{@events.first.stream_id}/#{find_seq(1)}')) } }) do
                  '←'
                end
                button(disabled: disabled_forward,
                       data: { on: { click: %(@get('/#{@href_prefix}/#{@events.first.stream_id}/#{find_seq(-1)}')) } }) do
                  '→'
                end
                small { "current version: #{@seq} " }
              end

              div(class: 'switches') do
                button(class: 'toggle-payloads', data: { on: { click: '$showPayloads = !$showPayloads' } }) do
                  span(data: { text: '$showPayloads ? "Hide payloads" : "Show payloads"' })
                end

                Components::Action(Todos::ListActor[:toggle_commands], attrs: { class: 'toggle-commands' }) do |_form|
                  button { @show_commands ? 'Hide commands' : 'Show commands' }
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

    private def find_seq(plus)
      index = @current_index + plus
      index = 0 if index.negative?
      index = @events.size - 1 if index >= @events.size
      @events[index].seq
    end
  end
end
