require 'tilt'

module Librato
  module Services
    module Helpers
      module AlertHelpers
        def self.sample_alert_payload
          {
            :alert => {
              :id => 12345
            },
            :metric => {
              :name => "my_sample_alert",
              :type => "gauge"
            },
            :measurement => { :value => 2345.9, :source => "r3.acme.com" },
            :trigger_time => 1321311840
          }.with_indifferent_access
        end

        def self.sample_alert_payload_multiple_measurements
          {
            :alert => {
              :id => 12345
            },
            :metric => {
              :name => "my_sample_alert",
              :type => "gauge"
            },
            :measurements => [
              { :value => 2345.9, :source => "r3.acme.com" },
              { :value => 123,    :source => "r2.acme.com" }
            ],
            :trigger_time => 1321311840
          }.with_indifferent_access
        end

        def get_measurements(body)
          measurements = body['measurements'] || []
          measurements << body['measurement']
          measurements.compact
        end

        def erb(template, target_binding)
          ERB.new(template, nil, '-').result(target_binding)
        end

        def h(text)
          ERB::Util.h(text)
        end

        def unindent(string)
          indentation = string[/\A\s*/]
          string.strip.gsub(/^#{indentation}/, "") + "\n"
        end

        def pluralize(count, singular, plural = nil)
          "#{count || 0} " + ((count == 1 || count =~ /^1(\.0+)?$/) ? singular : (plural || singular.pluralize))
        end

        def metric_link(type, name)
          "https://#{ENV['METRICS_APP_URL']}/metrics/#{name}"
        end
      end
    end
  end
end
