require File.expand_path('../helper', __FILE__)

class VictorOpsTest < Librato::Services::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post('/integrations/generic/20131114/f0c05b89-7099-45b3-9c0e-f8c9a8f8a97b'){ |env| [200, {}, ''] }
    end

    @params = { api_key: 'f0c05b89-7099-45b3-9c0e-f8c9a8f8a97b' }
  end

  def test_validattions

  end

  def test_alerts
    svc = service(:alert, @params, alert_payload)
    @stubs.post '/generic/2010-04-15/create_event.json' do |env|
      [200, {}, '']
    end
    svc.receive_alert
  end

  def service(*args)
    super Service::VictorOps, *args
  end
end
