require File.expand_path('../helper', __FILE__)
require 'timeout'

module Librato::Services
  class HipchatTest < Librato::Services::TestCase
    def setup
      @settings = { auth_token: "token", from: "who", room_id: "the_room", notify: "1" }
    end

    class TimesOutOnceHipchat
      attr_writer :success
      attr_accessor :times
      def initialize(success = true)
        @success=success
        @messages = []
        @times = 0
      end
      def send(from, msg, opts = {})
        @times += 1
        if @times == 1
          raise Timeout::Error
        end
        @messages << msg
        @success
      end
      def message(idx=0)
        @messages[idx]
      end
    end

    class FakeHipchat
      attr_writer :success
      def initialize(success = true)
        @success=success
        @messages = []
      end
      def send(from, msg, opts = {})
        @messages << msg
        @success
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

    def test_receive_validate_invalid_notify
      errors = {}
      service = service(:alert, @settings.merge(notify: "bad value"), alert_payload)
      assert !service.receive_validate(errors)
      errors = {}
      service = service(:alert, @settings.merge(notify: "1"), alert_payload)
      assert service.receive_validate(errors)
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
      @room = { @settings[:room_id] => fake_hipchat }
      service = service(:alert, @settings, alert_payload_multiple_measurements)
      service.hipchat = @room
      alert_message = service.alert_message
      service.receive_alert
      assert alert_message == fake_hipchat.message
    end

    def test_new_alert
      fake_hipchat = FakeHipchat.new
      @room = { @settings[:room_id] => fake_hipchat }
      service = service(:alert, @settings, new_alert_payload)
      service.hipchat = @room
      alert_message = service.alert_message
      service.receive_alert
      assert alert_message == fake_hipchat.message
    end

    def test_alert_retries_on_timeout
      fake_hipchat = TimesOutOnceHipchat.new
      @room = { @settings[:room_id] => fake_hipchat }
      service = service(:alert, @settings, new_alert_payload)
      service.hipchat = @room
      alert_message = service.alert_message
      service.receive_alert
      assert alert_message == fake_hipchat.message
      assert fake_hipchat.times == 2 # was called twice
    end

    def test_alert
      fake_hipchat = FakeHipchat.new
      @room = { @settings[:room_id] => fake_hipchat }
      service = service(:alert, @settings, alert_payload)
      service.hipchat = @room
      alert_message = service.alert_message
      service.receive_alert
      assert alert_message == fake_hipchat.message
    end

    def test_failure
      fake_hipchat = FakeHipchat.new(false) # will return a false success response
      @room = { @settings[:room_id] => fake_hipchat }
      service = service(:alert, @settings, alert_payload)
      service.hipchat = @room
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
      @room = { @settings[:room_id] => fake_hipchat }
      service = service(:snapshot, @settings, snapshot_payload)
      service.hipchat = @room
      snapshot_message = service.snapshot_message
      service.receive_snapshot
      assert snapshot_message == fake_hipchat.message
    end

    def service(*args)
      super Librato::Services::Service::Hipchat, *args
    end
  end
end
