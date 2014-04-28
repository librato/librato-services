require File.expand_path('../helper', __FILE__)

class SlackTest < Librato::Services::TestCase
  def setup
    @settings = { :url => "https://example.com?token=foo" }
    @stub_url = URI.parse(@settings[:url]).request_uri
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_validations
    svc = service(:alert, @settings, new_alert_payload)
    errors = {}
    assert(svc.receive_validate(errors))
    assert_equal(0, errors.length)

    svc = service(:alert, {}, new_alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    assert(!errors[:url].nil?)
  end

  def test_v1_alerts
    svc = service(:alert, @settings, alert_payload)

    @stubs.post @stub_url do |env|
      raise 'should not fire'
      [200, {}, '']
    end

    assert_raises(Librato::Services::Service::ConfigurationError) { svc.receive_alert }
  end


  def test_v2_custom_alerts
    svc = service(:alert, @settings, new_alert_payload)

    @stubs.post @stub_url do |env|
      payload = JSON.parse(env[:body])
      assert_not_nil(payload["alert_text"])
      assert_not_nil(payload["alert_url"])
      [200, {}, '']
    end

    svc.receive_alert
  end


  def service(*args)
    super Service::Slack, *args
  end
end
