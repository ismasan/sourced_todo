# frozen_string_literal: true

module Pages
  class SourcedPage < Phlex::HTML
    def initialize(stats:)
      @stats = stats
    end

    def view_template
      Layouts::Layout(title: 'Sourced', sse: '/sourced') do
        div id: 'container' do
          div id: 'main' do
            h1 { 'Sourced Dashboard' }
            render Consumers.new(stats: @stats)
          end
        end
      end
    end

    class Consumers < Phlex::HTML
      WIDTH = 1000

      def initialize(stats:)
        @tip = stats.max_global_seq
        @total_streams = stats.stream_count
        @groups = stats.groups.map do |g|
          min = (g[:oldest_processed].to_f / stats.max_global_seq) * WIDTH
          max = (1 - (g[:newest_processed].to_f / stats.max_global_seq)) * WIDTH
          g.merge(min:, max:)
        end
      end

      def view_template
        div(id: 'consumers', class: 'consumers', style: "width:#{WIDTH}px") do
          div(class: 'stream-container') do
            div(class: 'stream-label') do
              strong { 'Global Event Stream' }
              small { " (#{@total_streams} streams)" }
            end
            div(class: 'stream-bar global-stream') do
              div(class: 'progress-marker', style: 'width: 100%') do
                div(class: 'tooltip tooltip-max') { "tip: #{@tip}" }
              end
            end
          end

          @groups.each do |group|
            div(class: 'stream-container') do
              div(class: 'stream-label') do
                strong { group[:group_id] }
                small { " (#{group[:stream_count]} streams)" }
              end
              div(class: 'stream-bar') do
                div(class: 'lower-range', style: "width:#{group[:min]}px") do
                  div(class: 'tooltip') { group[:oldest_processed] }
                end
                div(class: 'upper-range', style: "width:#{group[:max]}px") do
                  div(class: 'tooltip') { group[:newest_processed] }
                end
              end
            end
          end
        end
      end
    end
  end
end
