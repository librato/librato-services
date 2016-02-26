require File.expand_path('../helper', __FILE__)

class NeptuneTest < Librato::Services::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_validations
    # Happy case
    svc = service(:alert, {:api_key => "test_api_key"}, alert_payload)
    errors = {}
    assert(svc.receive_validate(errors))
    assert_equal(0, errors.length)

    # api_key missing
    svc = service(:alert, {}, alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    assert(!errors[:api_key].nil?)

    # Test empty api_key
    svc = service(:alert, {:api_key => ""}, alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    assert(!errors[:api_key].nil?)
  end

  def test_alerts_multiple_measurements
    path = "/api/v1/trigger/channel/librato/test_api_key"
    svc = service(:alert, { :api_key => 'test_api_key'}, alert_payload_multiple_measurements)

    @stubs.post "#{path}" do |env|
      [200, {}, '']
    end

    svc.receive_alert
  end

  def test_alerts
    path = "/api/v1/trigger/channel/librato/test_api_key"
    svc = service(:alert, { :api_key => 'test_api_key'}, alert_payload)

    @stubs.post "#{path}" do |env|
      [200, {}, '']
    end

    svc.receive_alert
  end

  def test_new_alerts
    path = "/api/v1/trigger/channel/librato/test_api_key"
    payload = new_alert_payload.dup
    svc = service(:alert, { :api_key => 'test_api_key'}, payload)

    @stubs.post "#{path}" do |env|
      payload = JSON.parse(env[:body][:payload])
      assert_equal ["account", "alert", "conditions", "incident_key", "trigger_time", "triggered_by_user_test", "type", "violations"], payload.keys.sort
      assert_equal 123, payload['alert']['id']
      assert_equal 'Some alert name', payload['alert']['name']
      #assert_equal 'trigger', payload['type']
      assert_equal 1, payload['conditions'].length
      assert_equal "foo@example.com", payload['account']
      assert_equal false, payload['triggered_by_user_test']
      violations = payload['violations']
      foo_bar_violations = violations['foo.bar']
      assert_equal 1, foo_bar_violations.length
      assert_equal 'metric.name', foo_bar_violations[0]['metric']
      [200, {}, '']
    end

    svc.receive_alert
  end

  def test_new_alerts_clearing
    path = "/api/v1/trigger/channel/librato/test_api_key"
    payload = new_alert_payload.dup
    payload[:clear] = "normal"
    svc = service(:alert, { :api_key => 'test_api_key'}, payload)

    @stubs.post "#{path}" do |env|
      payload = JSON.parse(env[:body][:payload])
      assert_equal ["account", "alert", "conditions", "incident_key", "trigger_time", "triggered_by_user_test", "type", "violations"], payload.keys.sort
      assert_equal 123, payload['alert']['id']
      assert_equal 'resolve', payload['type']
      assert_equal 'Some alert name', payload['alert']['name']
      assert_equal 1, payload['conditions'].length
      assert_equal "foo@example.com", payload['account']
      assert_equal false, payload['triggered_by_user_test']
      violations = payload['violations']
      foo_bar_violations = violations['foo.bar']
      assert_equal 1, foo_bar_violations.length
      assert_equal 'metric.name', foo_bar_violations[0]['metric']
      [200, {}, '']
    end

    svc.receive_alert
  end

  def test_new_alert_test_trigger
    path = "/api/v1/trigger/channel/librato/test_api_key"
    payload = new_alert_payload.dup
    payload[:triggered_by_user_test] = true
    svc = service(:alert, { :api_key => 'test_api_key' }, payload)

    @stubs.post "#{path}" do |env|
      payload = JSON.parse(env[:body][:payload])
      assert_equal true, payload['triggered_by_user_test']
      [200, {}, '']
    end

    svc.receive_alert
  end

  def service(*args)
    super Service::Neptune, *args
  end
end
