require File.expand_path('../helper', __FILE__)

module Librato::Services
  class PagerdutyV2Test < Librato::Services::TestCase
    def setup
      @stubs = Faraday::Adapter::Test::Stubs.new
    end

    def test_validations
      params = {
        routing_key: 'k',
        description: 'd',
        severity: 's',
      }

      0.upto(params.keys.length - 1) do |i|
        opts = {}
        0.upto(i) do |j|
          opts[params.keys[j]] = params[params.keys[j]]
        end
        svc = service(:alert, opts, alert_payload)
        errors = {}
        ret = svc.receive_validate(errors)
        success = i == params.keys.length - 1
        assert_equal(success, ret, "opts not complete: #{opts}")
        assert_equal(0, errors.length) if success
      end
    end

    def test_new_alerts
      svc = service(:alert, {
        routing_key:  'k',
        description:  'Some alert name',
        severity:  'test',
        group:  'testing',
        incident_key:  'globalkey'
      }, new_alert_payload)

      @stubs.post svc.class::EVENTS_API_URL do |env|
        body = env[:body]
        assert_not_nil body

        assert_equal 'k', body[:routing_key]
        assert_equal 'trigger', body[:event_action]
        assert_equal 'globalkey-foo', body[:dedup_key]

        payload = body[:payload]
        assert_not_nil payload

        assert_equal 'Some alert name', payload[:summary]
        assert_equal 'foo.bar', payload[:source]
        assert_equal 'test', payload[:severity]
        assert_equal 12321123, payload[:timestamp]
        assert_equal 'testing', payload[:group]
        assert_equal 'metric.name', payload[:class]

        custom_details = payload[:custom_details]
        assert_not_nil custom_details

        assert_not_nil custom_details[:alert]
        assert_not_nil custom_details[:conditions]
        assert_not_nil custom_details[:violations]

        links = body[:links]
        assert_not_nil links
        assert_equal 'https://metrics.librato.com/alerts/123', links[0][:href]
        assert_equal 'Alert URL', links[0][:text]
        assert_equal 'http://runbooks.com/howtodoit', links[1][:href]
        assert_equal 'Runbook URL', links[1][:text]

        [200, {}, '']
      end

      svc.receive_alert
    end

    def test_new_alerts_clearing
      payload = new_alert_payload.dup
      payload[:clear] = "manual"
      svc = service(:alert, {
        routing_key:  'k',
        description:  'Some alert name',
        severity:  'test'
      }, payload)

      @stubs.post svc.class::EVENTS_API_URL do |env|
        body = env[:body]
        assert_not_nil body

        assert_equal 'k', body[:routing_key]
        assert_equal 'resolve', body[:event_action]
        assert_equal 'foo', body[:dedup_key]

        payload = body[:payload]
        assert_not_nil payload

        assert_equal 'Some alert name', payload[:summary]
        assert_equal 'foo.bar', payload[:source]
        assert_equal 'test', payload[:severity]
        assert_equal 12321123, payload[:timestamp]
        assert_equal 'metric.name', payload[:class]

        custom_details = payload[:custom_details]
        assert_not_nil custom_details

        assert_not_nil custom_details[:alert]
        assert_not_nil custom_details[:conditions]
        assert_not_nil custom_details[:violations]

        links = body[:links]
        assert_not_nil links
        assert_equal 'https://metrics.librato.com/alerts/123', links[0][:href]
        assert_equal 'Alert URL', links[0][:text]
        assert_equal 'http://runbooks.com/howtodoit', links[1][:href]
        assert_equal 'Runbook URL', links[1][:text]
        [200, {}, '']
      end

      svc.receive_alert
    end

    def service(*args)
      super Librato::Services::Service::PagerdutyV2, *args
    end
  end
end
