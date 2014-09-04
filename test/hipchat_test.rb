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
    settings = payload = {}
    service = service(:dummy, settings, payload)
    errors = {}
    result = service.receive_validate(errors)
    refute result
    @settings.keys.each {|setting| assert_equal "is required", errors[setting]}
  end

  def test_receive_validate_strips_token
    @settings[:auth_token] = ' abc '
    payload = {}
    service = service(:dummy, @settings, payload)
    assert service.receive_validate
    assert @settings[:auth_token] == 'abc', "Expected token whitespace to be stripped"
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

  def test_failure
    fake_hipchat = FakeHipchat.new(false) # will return a false success response
    service = service(:alert, @settings, alert_payload)
    service.hipchat = fake_hipchat
    failed = false
    begin
      service.receive_alert
    rescue Exception
      # ok
      failed = true
    end
    assert failed
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
