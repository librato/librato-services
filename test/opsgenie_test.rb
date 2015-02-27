require File.expand_path('../helper', __FILE__)

class OpsGenieTest < Librato::Services::TestCase
  def setup
    @settings = { :api_key => "my api key" }
    @stub_url = URI.parse("https://api.opsgenie.com/v1/json/librato").request_uri
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_v2_alert
    payload = new_alert_payload.dup
    svc = service(:alert, @settings, payload)
    @stubs.post @stub_url do |env|
      [200, {}, '']
    end
    svc.receive_alert
  end

  def service(*args)
    super Service::OpsGenie, *args
  end
end
