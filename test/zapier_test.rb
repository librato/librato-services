require File.expand_path('../helper', __FILE__)

class ZapierTest < Librato::Services::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @settings = { :url => 'https://zapier.com/hooks/catch/abc123/' }
    @payload = new_alert_payload.dup
    @service = service(:alert, @settings, @payload)
  end

  def test_receive_validate
    errors = {}
    assert(@service.receive_validate(errors))
    assert_equal(0, errors.length)

    svc = service(:alert, {}, @payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
  end

  def test_receive_alert
    @stubs.post URI.parse(@settings[:url]).request_uri do |env|
      [200, {}, '']
    end
    assert(@service.receive_alert)
  end

  def test_body
    expected_keys = [:id, :name, :description, :runbook_url, :violations]
    assert_equal(expected_keys, @service.body.keys)
  end

  def test_headers
    expected_keys = ['Content-Type']
    assert_equal(expected_keys, @service.headers.keys)
  end

  def test_present
    assert_equal(true, @service.present?("foobar"))
    assert_equal(false, @service.present?(""))
  end

  def service(*args)
    super Service::Zapier, *args
  end
end
