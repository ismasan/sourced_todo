module Components
  class Action < Phlex::HTML
    def initialize(command_class, attrs: {}, payload: {}, on: 'submit')
      @hidden_payload = payload
      @command = command_class.new(payload:)
      @attrs = attrs
      @on = on
    end

    def view_template
      data = { 
        "on-#{@on}" => "@post('#{url('/commands')}', {contentType: 'form'})", 
        'indicator-fetching' => true
      }
      attrs = @attrs.merge(data:)

      form(**attrs) do
        input(type: 'hidden', name: 'command[stream_id]', value: command.stream_id) if command.stream_id
        input(type: 'hidden', name: 'command[type]', value: command.type)

        hidden_payload.to_h.each do |key, value|
          input(type: 'hidden', name: "command[payload][#{key}]", value:)
        end

        yield
      end
    end

    def text_field(name, args = {})
      name = "command[payload][#{name}]"
      input **args.merge(type: 'text', name:)
    end

    def check_box(name, args = {})
      name = "command[payload][#{name}]"
      input **args.merge(type: 'checkbox', name:)
    end

    private

    attr_reader :command, :hidden_payload
  end
end
