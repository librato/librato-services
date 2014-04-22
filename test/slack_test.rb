require File.expand_path('../helper', __FILE__)

class SlackTest < Librato::Services::TestCase
  def setup
    token = "foo"
    @path = "/services/hooks/incoming-webhook?token=%s" % [token]
    @settings = { :subdomain => "librato", :token => token }
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_validations
    svc = service(:alert, @settings, alert_payload)
    errors = {}
    assert(svc.receive_validate(errors))
    assert_equal(0, errors.length)

    svc = service(:alert, {}, alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(2, errors.length)
    assert(!errors[:subdomain].nil?)
    assert(!errors[:token].nil?)
  end

  def test_v1_alerts
    svc = service(:alert, @settings, alert_payload)

    @stubs.post @path do |env|
      raise 'should not fire'
      [200, {}, '']
    end

    assert_raises(Librato::Services::Service::ConfigurationError) { svc.receive_alert }
  end

  def test_v2_alerts
    svc = service(:alert, @settings, new_alert_payload)

    @stubs.post @path do |env|
      [200, {}, '']
    end

    svc.receive_alert
  end

  def service(*args)
    super Service::Slack, *args
  end
end
