module Components
  class Command < Component
    LocalID = Data.define(:name) do
      def to_s = name

      def sub(n)
        self.class.new("#{name}-#{n}")
      end
    end

    class ErrorMessages < Phlex::HTML
      def initialize(field_id, errors = [])
        @id = [field_id, 'errors'].join('-')
        @errors = Array(errors).join(', ')
      end

      def view_template
        span(id: @id, class: 'command-field__errors') { @errors }
      end
    end

    def initialize(command_class, attrs = {})
      @on = attrs.delete(:on) || 'submit'
      stream_id = attrs.delete(:stream_id)
      args = {}
      args[:stream_id] = stream_id if stream_id
      @command = command_class.new(args)
      @attrs = attrs
      @cid = LocalID.new(['cmd', SecureRandom.hex(3)].join)
    end

    def view_template
      local_data = _d.on[@on].post(url('/commands'), content_type: 'form').to_h.merge(
        'indicator-fetching' => true
      )
      data = @attrs.fetch(:data, {}).merge(local_data)
      attrs = @attrs.merge(data:)

      form(**attrs) do
        input(type: 'hidden', name: 'command[stream_id]', value: command.stream_id) if command.stream_id
        input(type: 'hidden', name: 'command[type]', value: command.type)
        input(type: 'hidden', name: 'command[_cid]', value: @cid.to_s)

        yield
      end
    end

    def payload_fields(fields = {})
      fields.each do |key, value|
        input(type: 'hidden', name: "command[payload][#{key}]", value:)
      end
    end

    def text_field(name, args = {})
      with_errors(name) do |id|
        input **args.merge(id:, type: 'text', name: "command[payload][#{name}]")
      end
    end

    def check_box(name, args = {})
      with_errors(name) do |id|
        input **args.merge(id: ,type: 'checkbox', name: "command[payload][#{name}]")
      end
    end

    private

    def with_errors(name, &)
      #[cid]-[name]
      field_id = @cid.sub(name)

      # [cid]-[name]-wrapper
      div id: field_id.sub('wrapper').to_s, class: 'command-field' do
        yield field_id.to_s
        #[cid]-[name]-errors
        render ErrorMessages.new(field_id)
      end
    end

    attr_reader :command, :hidden_payload
  end
end
