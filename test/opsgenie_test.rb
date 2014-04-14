require File.expand_path('../helper', __FILE__)

class OpsGenieTest < Librato::Services::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end
  
  def test_alerts
    svc = service(:alert, {
                    :customer_key => 'test_api_key'
                  }, alert_payload)
    
    @stubs.post '/v1/json/librato' do |env|
      [200, {}, '']
    end
    
    svc.receive_alert
  end
  
  def service(*args)
    super Service::OpsGenie, *args
  end
end
