require File.expand_path('../helper', __FILE__)

class BigPandaTest < Librato::Services::TestCase
  def setup
    @settings = {:app_key => 'my api key', :token => 'my token', :application => 'webapp'}
    @stub_url = URI.parse('https://api.bigpanda.io/data/v2/alerts').request_uri
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
    super Service::BigPanda, *args
  end
end
