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

    assert_equal 2, svc.client.events.count

    user_id, event_name, payload = *svc.client.events[0]
    assert_equal 123, user_id
    assert_equal event_name, "test_event"
    assert_equal 3.14, payload[:measurement][:value]
    assert_equal "bar", payload[:foo]

    user_id, event_name, payload = *svc.client.events[1]
    assert_equal 234, user_id
    assert_equal event_name, "test_event"
    assert_equal 1.23, payload[:measurement][:value]
    assert_equal "bar", payload[:foo]
  end

  def test_new_alerts
    svc = service(:alert,
                  {"site_id" => "x", "api_key" => "x", "event_name" => "test_event"}.with_indifferent_access,
                  new_customerio_payload)
    svc.client = MockCustomerIo.new
    svc.receive_alert

    assert_equal 2, svc.client.events.count

    user_id, event_name, payload = *svc.client.events[0]
    assert_equal 1, user_id
    assert_equal event_name, "test_event"
    assert_equal 1, payload.length
    assert_equal "metric.name", payload[0][:metric]
    assert_equal 100, payload[0][:value]
    assert_equal 1, payload[0][:condition_violated]
    assert_equal "bar", payload[0][:foo]

    user_id, event_name, payload = *svc.client.events[1]
    assert_equal 2, user_id
    assert_equal event_name, "test_event"
    assert_equal 1, payload.length
    assert_equal "another.metric", payload[0][:metric]
    assert_equal 300, payload[0][:value]
    assert_equal 1, payload[0][:condition_violated]
    assert_equal "bar", payload[0][:foo]
  end

  def service(*args)
    super Service::CustomerIo, *args
  end

  def new_customerio_payload
    {
      alert: { id: 12345, name: "my alert", version: 2},
      conditions: [{type: "above", threshold: 10, id: 1}],
      violations: {
        "foo:bar.uid:1" => [{
          metric: "metric.name", value: 100, recorded_at: 1389391083,
          condition_violated: 1
        }],
        "foo:bar.uid:2" => [{
          metric: "another.metric", value: 300, recorded_at: 1389391083,
          condition_violated: 1
        }]
      },
      trigger_time: Time.now.to_i
    }.with_indifferent_access
  end

  # Customer io requires a specially crafted source name of `uid:123` to work
  def customerio_payload
    {
      alert: { id: 12345 },
      metric: { name: "sample_alert", type: "gauge" },
      measurements: [{
        value: 3.14,
        source: "foo:bar.uid:123"
      }, {
        value: 1.23,
        source: "foo:bar.uid:234"
      }],
      trigger_time: Time.now.to_i
    }.with_indifferent_access
  end
end


