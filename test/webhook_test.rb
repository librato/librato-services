require File.expand_path('../helper', __FILE__)

class WebhookTest < Librato::Services::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_validations
    svc = service(:alert, {:url => "http://foobar.com/push"}, payload)
    errors = {}
    assert(svc.receive_validate(errors))
    assert_equal(0, errors.length)

    svc = service(:alert, {}, payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    assert(!errors[:url].nil?)

    svc = service(:alert, {:url => "http://user@@foobar.com:/blah"}, payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    assert(!errors[:url].nil?)
  end

  def test_alerts
    path = "/post_path.json"
    url = "http://localhost#{path}"
    svc = service(:alert, { :url => url }, payload)

    @stubs.post "#{path}" do |env|
      [200, {}, '']
    end

    svc.receive_alert
  end

  def service(*args)
    super Service::Webhook, *args
  end
end
