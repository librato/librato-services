require File.expand_path('../helper', __FILE__)

class HipchatTest < Librato::Services::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @settings = { auth_token: "token", from: "who", room_id: "the_room", notify: "1" }
    @test_message = "Test message from Librato Hipchat integration"
  end

  def stub_message_call(message, response_code)
    message = URI.escape(message)
    @stubs.post "/v1/rooms/message?auth_token=token&from=who&message=#{message}&room_id=the_room&notify=1" do |env|
      [response_code, {}, '']
    end
  end

  def test_receive_validate
    errors = {}
    stub_message_call(@test_message, 200)

    service = service(:alert, @settings, alert_payload)
    result = service.receive_validate(errors)

    assert result
    assert errors.empty?
  end

  def test_receive_validate_missing_arguments
    errors = {}
    opts = {}
    service = service(:alert, {}, alert_payload)
    result = service.receive_validate(errors)

    assert !result
    @settings.keys.each {|setting| assert_equal "Is required", errors[setting]}
  end

  def test_alert_multiple_measurements
    service = service(:alert, @settings, alert_payload_multiple_measurements)

    stub_message_call(@test_message, 200)
    alert_message = service.alert_message
    stub_message_call(alert_message, 200)

    service.receive_alert
  end

  def test_alert
    service = service(:alert, @settings, alert_payload)

    stub_message_call(@test_message, 200)
    alert_message = service.alert_message
    stub_message_call(alert_message, 200)

    service.receive_alert
  end

  def test_snapshot
    service = service(:snapshot, @settings, snapshot_payload)

    stub_message_call(@test_message, 200)
    snapshot_message = service.snapshot_message
    stub_message_call(snapshot_message, 200)

    service.receive_snapshot
  end

  def service(*args)
    super Service::Hipchat, *args
  end
end
