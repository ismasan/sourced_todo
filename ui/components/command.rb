module Components
  class Command < Phlex::HTML
    Signal = Data.define(:name) do
      def ref = "$#{name}"
      def to_s = name
      def quoted = "'#{name}'"

      def signal(n)
        self.class.new("#{name}.#{n}")
      end
    end

    def initialize(command_class, stream_id: nil, attrs: {}, payload: {}, on: 'submit')
      @hidden_payload = payload
      args = { payload: }
      args[:stream_id] = stream_id if stream_id
      @command = command_class.new(args)
      @attrs = attrs
      @on = on
      @cid = Signal.new(['cmd', SecureRandom.hex(3)].join)
    end

    def view_template
      data = @attrs.fetch(:data, {}).merge(
        "on-#{@on}" => "@post('#{url('/commands')}', {contentType: 'form'})", 
        'signals-cid' => @cid.quoted,
        'indicator-fetching' => true
      )
      attrs = @attrs.merge(data:)

      form(**attrs) do
        input(type: 'hidden', name: 'command[stream_id]', value: command.stream_id) if command.stream_id
        input(type: 'hidden', name: 'command[type]', value: command.type)
        input(type: 'hidden', name: 'command[_cid]', value: @cid.to_s)

        hidden_payload.to_h.each do |key, value|
          input(type: 'hidden', name: "command[payload][#{key}]", value:)
        end

        yield
      end
    end

    def text_field(name, args = {})
      with_errors(name) do
        input **args.merge(type: 'text', name: "command[payload][#{name}]")
      end
    end

    def check_box(name, args = {})
      input **args.merge(type: 'checkbox', name: "command[payload][#{name}]")
    end

    private

    def with_errors(name, &)
      signal = @cid.signal(name)

      div(class: 'command-field', data: { "signals-#{signal}" => 'false', 'class-errors' => signal.ref }) do
        yield
        span(class: 'command-field__errors', data: { show: signal.ref, text: signal.ref }) { '...' }
      end
    end

    attr_reader :command, :hidden_payload
  end
end
