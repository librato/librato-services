require 'tilt'
require 'active_support'

module Librato
  module Services
    module Helpers
      module AlertHelpers
        def self.sample_alert_payload
          {
            :alert => {
              :id => 12345,
              :name => ""
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

        #TODO rename when it's no longer "new"
        def self.sample_new_alert_payload
          ::HashWithIndifferentAccess.new({
            user_id: 1,
            incident_key: "foo",
            alert: {id: 123,
                    name: "Some alert name",
                    version: 2,
                    description: "Verbose alert explanation",
                    runbook_url: "http://runbooks.com/howtodoit"},
            auth: {email:"foo@example.com", annotations_token:"lol"},
            service_type: "campfire",
            event_type: "alert",
            triggered_by_user_test: false,
            trigger_time: 12321123,
            conditions: [{type: "above", threshold: 10, id: 1}],
            violations: {
              "foo.bar" => [{
                metric: "metric.name", value: 100, recorded_at: 1389391083,
                condition_violated: 1
              }]
            }
          })
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

        def alert_link(id)
          "https://#{ENV['METRICS_APP_URL']}/alerts/#{id}"
        end

        # TODO: fix for specific alert id?
        def payload_link(payload)
          if payload[:alert][:version] == 2
            "https://#{ENV['METRICS_APP_URL']}/metrics/"
          else
            metric_link(payload[:metric][:type], payload[:metric][:name])
          end
        end
      end
    end
  end
end
