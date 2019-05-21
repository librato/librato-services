require 'redcarpet'
require 'active_support/core_ext/string/filters.rb'

require_relative 'helpers/alert_helpers'
require_relative 'numbers'

# TODO
# This has grown to the point where it may be worth generating an Alert
# object that is pushed into a set of templates for HTML, Markdown, Slack, etc.
module Librato
  module Services
    class Output
      include Helpers::AlertHelpers

      attr_reader :violations, :conditions, :alert, :clear, :trigger_time, :alert_url
      def initialize(payload, add_test_notice=true)
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
        @auth = payload[:auth] || {}
        @show_test_notice = (add_test_notice and payload[:triggered_by_user_test])
        @alert_url = alert_link(payload.with_indifferent_access)
      end

      def html
        @html ||= generate_html
      end

      def markdown
        generate_markdown
      end

      def generate_html
        Output.renderer.render(markdown)
      end

      def generate_markdown
        if @clear
          generate_alert_cleared
        else
          generate_alert_raised
        end
      end

      def generate_alert_raised
        result_array = []
        if @show_test_notice
          result_array << ["# #{test_alert_message()}\n"]
        end
        result_array << ["# Alert #{@alert[:name]} has triggered!\n"]
        if @alert[:description]
          result_array << "Description: #{@alert[:description]}\n"
        end
        if @auth[:email]
          result_array << "Account: #{@auth[:email]}\n"
        end
        result_array << "Link: #{@alert_url}\n"
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

      def generate_alert_cleared
        alert_name = @alert[:name]
        trigger_time_utc = Time.at(trigger_time).utc
        case clear
        when "auto"
          lines = ["# Alert #{alert_name} was automatically cleared at #{trigger_time_utc}\n"]
        when "manual"
          lines = ["# Alert #{alert_name} was manually cleared at #{trigger_time_utc}\n"]
        else
          lines = ["# Alert #{alert_name} has cleared at #{trigger_time_utc}\n"]
        end
        if @alert[:description]
          lines << "Description: #{@alert[:description]}\n"
        end
        if @auth[:email]
          lines << "Account: #{@auth[:email]}\n"
        end
        lines << "Link: #{@alert_url}\n"
        lines.join("\n")
      end

      def format_measurement(measurement, source = nil)
        condition = @conditions[measurement[:condition_violated]]
        if source
          metric = "`#{measurement[:metric]}` from `#{source}`"
        else
          metric = "`#{measurement[:metric]}`"
        end
        violation_time = measurement[:end] || measurement[:recorded_at]
        "metric #{metric} was #{format_violation_type(condition, measurement)} recorded at #{format_time(violation_time)}"
      end

      def format_violation_type(condition, measurement)
        if condition[:type] == "absent"
          "absent for #{condition[:duration]} seconds"
        else
          threshold_value = condition[:threshold]
          actual_value = measurement[:value]
          formatted_value = Librato::Services::Numbers.format_for_threshold(threshold_value, actual_value)
          "#{condition[:type]} threshold #{threshold(condition,measurement)} with value #{formatted_value}"
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

      def sms_message
        unless @clear
          if valid_sms?
            violations_message
          else
            violations_message.truncate(140)
          end
        end
      end

      def valid_sms?
        violations_message.length <= 140
      end

      def violations_message
        violations.flat_map do |source, measurements|
          measurements.map { |measurement| format_measurement(measurement, source) }
        end.join('. ')
      end

      class << self
        def renderer
          @renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, lax_spacing: true, no_intra_emphasis: true)
        end
      end
    end
  end
end
