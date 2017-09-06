require File.expand_path('../helper', __FILE__)

module Librato::Services
  class VictorOpsTest < Librato::Services::TestCase

    def setup
      @settings = { api_key: 'some_keys', routing_key: 'five' }
      @stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/integrations/generic/20131114/alert/#{@settings[:api_key]}/#{@settings[:routing_key]}"){ |env| [200, {}, ''] }
        stub.post("/integrations/generic/20131114/alert/#{@settings[:api_key]}/has%20space"){ |env| [200, {}, ''] }
        stub.post("/integrations/generic/20131114/alert/#{@settings[:api_key]}/nil"){ |env| [200, {}, ''] }
      end
    end

    def test_validations
      svc = service(:alert, @settings, alert_payload)
      errors = {}
      assert svc.receive_validate(errors), 'Validation was false'
      assert_equal 0, errors.length

      # Test missing API key
      svc = service(:alert, {}, alert_payload)
      errors = {}
      assert !svc.receive_validate(errors), 'Validation was true'
      assert_equal 1, errors.length
    end

    def test_has_space_in_routing_key
      svc = service(:alert, {"api_key" => @settings[:api_key], "routing_key" => "has space"}.with_indifferent_access, new_alert_payload)
      resp = svc.receive_alert
      assert_equal 200, resp.status
    end

    def test_alerts
      service(:alert, @settings, alert_payload).receive_alert
      settings_no_routing_key = @settings.dup
      settings_no_routing_key.delete :routing_key
      service(:alert, settings_no_routing_key, alert_payload).receive_alert
    end

    def service(*args)
      super Librato::Services::Service::VictorOps, *args
    end
  end
end
