module Components
  class StatusBadge < Phlex::HTML
    def initialize(status, label: status)
      @status = status
      @label = label
    end

    def view_template
      span(class: "status-badge #{@status}") { @label }
    end
  end
end
