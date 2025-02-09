module Components
  class MessageRow < Phlex::HTML
    def initialize(event, href: nil, highlighted: false)
      @event = event
      @href = href
      @is_command = event.is_a?(Sourced::Command)
      @highlighted = highlighted
      @classes = [
        'event-card',
        'fade-in',
        (@is_command ? 'command' : 'event'),
        ('highlighted' if @highlighted)
      ]
    end

    def view_template
      div(id: event.id, class: @classes) do
        div(class: 'event-header') do
          span(class: 'event-sequence') do
            if @href
              a(data: { 'on-click' => %(@get('#{@href}')) }) { event.seq }
            else
              span { event.seq }
            end
          end
          producer_for(event)
          span(class: 'event-type') do
            if @href
              a(data: { 'on-click' => %(@get('#{@href}')) }) { event.type }
            else
              strong { event.type }
            end
          end
          span(class: 'event-timestamp') { event.created_at.to_s }
          span(class: 'event-correlation') do
            ref = url("/events/#{event.id}/correlation")
            a(href: '#', data: { 'on-click' => %(@get('#{ref}')) }) { '⇄' }
          end
        end
        if event.payload
          div(class: 'event-payload', data: { show: '$showPayloads' }) do
            JSON.pretty_generate(event.payload&.to_h || {})
          end
        end
      end
    end

    private

    attr_reader :event, :href, :is_command

    def producer_for(event)
      code(class: 'event-producer') { safe("#{event.metadata[:producer]} →") } if event.metadata[:producer]
    end
  end
end
