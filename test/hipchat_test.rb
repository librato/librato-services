require File.expand_path('../helper', __FILE__)

class HipchatTest < Librato::Services::TestCase
  def setup
    @settings = { auth_token: "token", from: "who", room_id: "the_room", notify: "1" }
  end

  class FakeResponse
    attr_reader :success
    def initialize(success)
      @success = success
    end
    def success?
      @success
    end
  end

  class FakeHipchat
    attr_writer :success
    def initialize(success = true)
      @success=success
      @messages = []
    end
    def rooms_message(room_id, from, msg, notify, color, format)
      @messages << msg
      FakeResponse.new(@success)
    end
    def message(idx=0)
      @messages[idx]
    end
  end

  def test_receive_validate
    errors = {}
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
    fake_hipchat = FakeHipchat.new
    service = service(:alert, @settings, alert_payload_multiple_measurements)
    service.hipchat = fake_hipchat
    alert_message = service.alert_message
    service.receive_alert
    assert alert_message == fake_hipchat.message
  end

  def test_new_alert
    fake_hipchat = FakeHipchat.new
    service = service(:alert, @settings, new_alert_payload)
    service.hipchat = fake_hipchat
    alert_message = service.alert_message
    service.receive_alert
    assert alert_message == fake_hipchat.message
  end

  def test_alert
    fake_hipchat = FakeHipchat.new
    service = service(:alert, @settings, alert_payload)
    service.hipchat = fake_hipchat
    alert_message = service.alert_message
    service.receive_alert
    assert alert_message == fake_hipchat.message
  end

  def test_snapshot
    fake_hipchat = FakeHipchat.new
    service = service(:snapshot, @settings, snapshot_payload)
    service.hipchat = fake_hipchat
    snapshot_message = service.snapshot_message
    service.receive_snapshot
    assert snapshot_message == fake_hipchat.message
  end

  def service(*args)
    super Service::Hipchat, *args
  end
end
