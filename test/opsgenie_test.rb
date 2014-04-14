require File.expand_path('../helper', __FILE__)

class OpsGenieTest < Librato::Services::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end
  
  def test_alerts
    svc = service(:alert, {
                    :customer_key => 'test_api_key'
                  }, alert_payload)
    
    svc.receive_alert
  end
  
  def service(*args)
    super Service::OpsGenie, *args
  end
end
