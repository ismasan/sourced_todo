# frozen_string_literal: true

module Components
  class InlineEdit < Phlex::HTML
    def initialize(enabled: true)
      @signal = ['_edit', SecureRandom.hex(3)].join
      @tid = [@signal, 'target'].join('-')
      @enabled = enabled
    end

    def view_template(&)
      if @enabled
        div(data: { "signals-#{@signal}" => 'false', 'on-click__outside' => "$#{@signal} = false" }, class: 'inline-edit') do
          yield
        end
      else
        yield
      end
    end

    def trigger(&)
      data = {}
      if @enabled
        click = <<~JS
        $#{@signal} = true; document.querySelector('##{@tid} input[type=text]').focus()
        JS

        data = { show: "!$#{@signal}", 'on-click' => click }
      end

      div(data: ) do
        yield
      end
    end

    def target(&)
      return unless @enabled

      div(id: @tid, data: { show: "$#{@signal}", 'sson-click__outside' => "$#{@signal} = false" }) do
        yield
      end
    end
  end
end
