require File.expand_path('../helper', __FILE__)

class OpsGenieTest < Librato::Services::TestCase
  def setup
    @settings = { :customer_key => "my customer key" }
    url = "https://api.opsgenie.com/v1/json/alert"
    @stub_url = URI.parse(url).request_uri
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def service(*args)
    super Service::OpsGenie, *args
  end
end
