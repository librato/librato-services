require File.expand_path('../helper', __FILE__)

class CustomerIoTest < Librato::Services::TestCase
  class MockCustomerIo
    attr_reader :events

    def initialize
      @events = []
    end

    def track(*args)
      events << args
    end

  end

  def test_alerts
    svc = service(:alert,
                  {"site_id" => "x", "api_key" => "x", "event_name" => "test_event"}.with_indifferent_access,
                  customerio_payload)
    svc.client = MockCustomerIo.new
    svc.receive_alert

    assert_equal 1, svc.client.events.count

    user_id, event_name, payload = *svc.client.events.first

    assert_equal 123, user_id
    assert_equal event_name, "test_event"
  end

  def service(*args)
    super Service::CustomerIo, *args
  end

  # Customer io requires a specially crafted source name of `uid:123` to work
  def customerio_payload
    {
      alert: { id: 12345 },
      metric: { name: "sample_alert", type: "gauge" },
      measurement: {
        value: 3.14,
        source: "uid:123"
      },
      trigger_time: Time.now.to_i
    }.with_indifferent_access
  end
end


