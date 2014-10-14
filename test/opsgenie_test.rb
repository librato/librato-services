require File.expand_path('../helper', __FILE__)

class OpsGenieTest < Librato::Services::TestCase
  def setup
    @settings = { :customer_key => "my customer key" }
    url = "https://api.opsgenie.com/v1/json/alert"
    @stub_url = URI.parse(url).request_uri
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_v2_alert_clear_normal
    payload = new_alert_payload.dup
    payload[:clear] = "normal"
    svc = service(:alert, @settings, payload)
    @stubs.post @stub_url do |env|
      assert_equal("Alert Some alert name has cleared at 1970-05-23 14:32:03 UTC", env[:body][:message])
      [200, {}, '']
    end
    svc.receive_alert_clear
  end

  def test_v2_alert_clear_unknown
    payload = new_alert_payload.dup
    payload[:clear] = "dont know"
    svc = service(:alert, @settings, payload)
    @stubs.post @stub_url do |env|
      assert_equal("Alert Some alert name has cleared at 1970-05-23 14:32:03 UTC", env[:body][:message])
      [200, {}, '']
    end
    svc.receive_alert_clear
  end

  def test_v2_alert_clear_manual
    payload = new_alert_payload.dup
    payload[:clear] = "manual"
    svc = service(:alert, @settings, payload)
    @stubs.post @stub_url do |env|
      assert_equal("Alert Some alert name was manually cleared at 1970-05-23 14:32:03 UTC", env[:body][:message])
      [200, {}, '']
    end
    svc.receive_alert_clear
  end

  def test_v2_alert_clear_auto
    payload = new_alert_payload.dup
    payload[:clear] = "auto"
    svc = service(:alert, @settings, payload)
    @stubs.post @stub_url do |env|
      assert_equal("Alert Some alert name was automatically cleared at 1970-05-23 14:32:03 UTC", env[:body][:message])
      [200, {}, '']
    end
    svc.receive_alert_clear
  end


  def service(*args)
    super Service::OpsGenie, *args
  end
end
