require File.expand_path('../helper', __FILE__)

class CampfireTest < Librato::Services::TestCase
  class MockCampfire
    class Room
      attr_reader :name, :lines, :pastes

      def initialize(name)
        @name  = name
        @lines = []
        @pastes = []
      end

      def speak(line)
        @lines << line
      end

      def paste(lines)
        @pastes << lines
      end
    end

    def rooms
      @rooms.values
    end

    def initialize()
      @rooms = {}
    end

    attr_reader :logged_out

    def find_room_by_name(name)
      @rooms[name] ||= Room.new(name)
    end
  end

  def test_new_alerts_payload
    svc = service(:alert, {"token" => "t", "subdomain" => "s", "room" => "r"}.with_indifferent_access, new_alert_payload)
    svc.campfire = MockCampfire.new
    svc.receive_alert

    assert_equal 1, svc.campfire.rooms.length
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 0, svc.campfire.rooms.first.lines.size
    assert_equal 1, svc.campfire.rooms.first.pastes.size # measurements
  end

  def test_alerts_multiple_measurements
    svc = service(:alert, {"token" => "t", "subdomain" => "s", "room" => "r"}.with_indifferent_access, alert_payload_multiple_measurements)
    svc.campfire = MockCampfire.new
    svc.receive_alert

    assert_equal 1, svc.campfire.rooms.length
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 1, svc.campfire.rooms.first.lines.size # summary
    assert_equal 1, svc.campfire.rooms.first.pastes.size # measurements
  end

  def test_alerts
    svc = service(:alert, {"token" => "t", "subdomain" => "s", "room" => "r"}.with_indifferent_access, alert_payload)
    svc.campfire = MockCampfire.new
    svc.receive_alert

    assert_equal 1, svc.campfire.rooms.length
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 1, svc.campfire.rooms.first.lines.size # summary
    assert_equal 0, svc.campfire.rooms.first.pastes.size # measurements
  end

  def test_snapshots
    svc = service(:snapshot, {"token" => "t", "subdomain" => "s", "room" => "r"}.with_indifferent_access, snapshot_payload)
    svc.campfire = MockCampfire.new
    svc.receive_snapshot

    assert_equal 1, svc.campfire.rooms.size
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 2, svc.campfire.rooms.first.lines.size # summary
    #assert_equal 1, svc.campfire.rooms.first.pastes.size # logs
  end

  def service(*args)
    super Service::Campfire, *args
  end
end

