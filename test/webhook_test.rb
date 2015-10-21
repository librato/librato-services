require File.expand_path('../helper', __FILE__)

class WebhookTest < Librato::Services::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_validations
    svc = service(:alert, {:url => "http://foobar.com/push"}, alert_payload)
    errors = {}
    assert(svc.receive_validate(errors))
    assert_equal(0, errors.length)

    svc = service(:alert, {}, alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    assert(!errors[:url].nil?)

    svc = service(:alert, {:url => "http://user@@foobar.com:/blah"}, alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    assert(!errors[:url].nil?)

    svc = service(:alert, {:url => "example.com/foo"}, alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    assert(!errors[:url].nil?)
  end

  def test_alerts_multiple_measurements
    path = "/post_path.json"
    url = "http://localhost#{path}"
    svc = service(:alert, { :url => url }, alert_payload_multiple_measurements)

    @stubs.post "#{path}" do |env|
      [200, {}, '']
    end

    svc.receive_alert
  end

  def test_alerts
    path = "/post_path.json"
    url = "http://localhost#{path}"
    svc = service(:alert, { :url => url }, alert_payload)

    @stubs.post "#{path}" do |env|
      [200, {}, '']
    end

    svc.receive_alert
  end

  def test_new_alerts
    path = "/post_path.json"
    url = "http://localhost#{path}"
    svc = service(:alert, { :url => url }, new_alert_payload)

    @stubs.post "#{path}" do |env|
      payload = JSON.parse(env[:body][:payload])
      assert_equal ["account", "alert", "conditions", "trigger_time", "triggered_by_user_test", "violations"], payload.keys.sort
      assert_equal 123, payload['alert']['id']
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
    path = "/post_path.json"
    url = "http://localhost#{path}"
    payload = new_alert_payload.dup
    payload[:triggered_by_user_test] = true
    svc = service(:alert, { :url => url }, payload)

    @stubs.post "#{path}" do |env|
      payload = JSON.parse(env[:body][:payload])
      assert_equal true, payload['triggered_by_user_test']
      [200, {}, '']
    end

    svc.receive_alert
  end

  def service(*args)
    super Service::Webhook, *args
  end
end
