require File.expand_path('../helper', __FILE__)

class SlackTest < Librato::Services::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_validations
    svc = service(:alert, {:subdomain => "tinyspeck", :token => "foo"}, alert_payload)
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

  def test_alerts
    token = "okfLErqIOHVRGK6OgX209dbW"
    subdomain = "tinyspeck"
    path = "/services/hooks/incoming-webhook?token=%s" % [token]
    svc = service(:alert, { :subdomain => subdomain, :token => token }, alert_payload)

    @stubs.post "#{path}" do |env|
      [200, {}, '']
    end

    svc.receive_alert
  end

  def service(*args)
    super Service::Slack, *args
  end
end
