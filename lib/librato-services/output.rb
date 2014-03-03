require 'redcarpet'

module Librato
  module Services
    class Output
      def initialize(payload)
        if !payload[:conditions] || !payload[:violations]
          raise "Invalid payload: #{payload}"
        end

        @conditions = payload[:conditions].inject({}) do |injected, value|
          injected[value[:id]] = value
          injected
        end
        @violations = payload[:violations]
        @alert = payload[:alert]
      end

      def html
        @html ||= generate_html
      end

      def markdown
        @markdown ||= generate_markdown
      end

      def generate_html
        Output.renderer.render(markdown)
      end

      def generate_markdown
        result_array = ["# Alert #{@alert[:name]} has triggered!\n"]
        @violations.each do |source, measurements|
          result_array << "Source `#{source}`:"
          measurements.each do |measurement|
            condition = @conditions[measurement[:condition_violated]]
            if condition[:type] == "absent"
              type_msg = "absent"
            else
              type_msg = "#{condition[:type]} threshold #{threshold(condition, measurement)} with value #{measurement[:value]}"
            end
            recorded_at = DateTime.strptime(measurement[:recorded_at].to_s, "%s").
                strftime("%a, %b %e %Y at %H:%M:%S UTC")
            result_array << "* metric `#{measurement[:metric]}` was #{type_msg} recorded at #{recorded_at}"
          end
          result_array << "" # To append a newline after each source group
        end
        runbook_url = @alert[:runbook_url]
        if !runbook_url.nil? && !runbook_url.empty?
          result_array << "Runbook: #{runbook_url}\n"
        end
        result_array.join("\n")
      end

      def threshold(condition, measurement)
        thresh_str = condition[:threshold].to_s
        duration = calculate_duration(measurement)
        if duration
          thresh_str += " over #{duration} seconds"
        end
        thresh_str
      end

      def calculate_duration(measurement)
        if measurement[:begin] && measurement[:end]
          measurement[:end] - measurement[:begin]
        else
          nil
        end
      end

      class << self
        def renderer
          @renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, lax_spacing: true)
        end
      end
    end
  end
end
