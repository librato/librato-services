require 'redcarpet'
require 'helpers/alert_helpers'

# TODO
# This has grown to the point where it may be worth generating an Alert
# object that is pushed into a set of templates for HTML, Markdown, Slack, etc.
module Librato
  module Services
    class Output
      include Helpers::AlertHelpers

      attr_reader :violations, :conditions, :alert, :clear, :trigger_time
      def initialize(payload)
        if !payload[:clear]
          # conditions and violations are required for faults
          if !payload[:conditions] || !payload[:violations] && !payload[:clear]
            raise "Invalid payload: #{payload}"
          end

          @conditions = payload[:conditions].inject({}) do |injected, value|
            injected[value[:id]] = value
            injected
          end
          @violations = payload[:violations]
        end
        @alert = payload[:alert]
        @clear = payload[:clear]
        @trigger_time = payload[:trigger_time]
      end

      def html
        @html ||= generate_html
      end

      def markdown(is_html=false)
        @markdown ||= generate_markdown(is_html)
      end

      def generate_html
        Output.renderer.render(markdown(is_html=true))
      end

      def generate_markdown(is_html=false)
        if @clear
          generate_alert_cleared(is_html)
        else
          generate_alert_raised(is_html)
        end
      end

      def format_alert_name(is_html=false)
        # Escape underscores in alert name for html formatting
        is_html ? @alert[:name].gsub('_', '\_') : @alert[:name]
      end

      def generate_alert_raised(is_html=false)
        result_array = ["# Alert #{format_alert_name(is_html)} has triggered!\n"]
        result_array << "Link: #{alert_link(@alert[:id])}\n"
        @violations.each do |source, measurements|
          result_array << "Source `#{source}`:"
          measurements.each do |measurement|
            result_array << "* " + format_measurement(measurement)
          end
          result_array << "" # To append a newline after each source group
        end
        runbook_url = @alert[:runbook_url]
        if !runbook_url.nil? && !runbook_url.empty?
          result_array << "Runbook: #{runbook_url}\n"
        end
        result_array.join("\n")
      end

      def generate_alert_cleared(is_html=false)
        alert_name = format_alert_name(is_html)
        trigger_time_utc = Time.at(trigger_time).utc
        case clear
        when "auto"
          lines = ["# Alert #{alert_name} was automatically cleared at #{trigger_time_utc}\n"]
        when "manual"
          lines = ["# Alert #{alert_name} was manually cleared at #{trigger_time_utc}\n"]
        else
          lines = ["# Alert #{alert_name} has cleared at #{trigger_time_utc}\n"]
        end
        lines << "Link: #{alert_link(@alert[:id])}\n"
        lines.join("\n")
      end

      def format_measurement(measurement)
        condition = @conditions[measurement[:condition_violated]]
        "metric `#{measurement[:metric]}` was #{format_violation_type(condition, measurement)} recorded at #{format_time(measurement[:recorded_at])}"
      end

      def format_violation_type(condition, measurement)
        if condition[:type] == "absent"
          "absent for #{condition[:duration]} seconds"
        else
          "#{condition[:type]} threshold #{threshold(condition, measurement)} with value #{measurement[:value]}"
        end
      end

      def format_time(time)
        DateTime.
          strptime(time.to_s, "%s").
          strftime("%a, %b %e %Y at %H:%M:%S UTC")
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
