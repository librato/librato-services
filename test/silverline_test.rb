require File.expand_path('../helper', __FILE__)

class SilverlineTest < PapertrailServices::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_logs
    svc = service(:logs, { :name => 'gauge' }, payload)

    @stubs.post '/v1/metrics.json' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def service(*args)
    super Service::Silverline, *args
  end
end