require File.expand_path('../helper', __FILE__)

class FlowdockTest < Librato::Services::TestCase
  class MockFlowdock
    attr_reader :chats, :inbox

    def initialize
      @chats = []
      @inbox = []
    end

    def push_to_chat(chat)
      @chats << chat
    end

    def push_to_team_inbox(mail)
      @inbox << mail
    end
  end

  def test_new_alerts
    svc = service(:alert, {"api_token" => "t", "user_name" => "Test"}.with_indifferent_access, new_alert_payload)
    svc.flowdock = MockFlowdock.new
    svc.receive_alert
    output = Librato::Services::Output.new(new_alert_payload)

    assert_equal 0, svc.flowdock.chats.count
    assert_equal 1, svc.flowdock.inbox.count
    assert_equal output.html, svc.flowdock.inbox.first[:content].to_s
  end

  def test_alerts_multiple_measurements
    svc = service(:alert, {"api_token" => "t", "user_name" => "Test"}.with_indifferent_access, alert_payload_multiple_measurements)
    svc.flowdock = MockFlowdock.new
    svc.receive_alert

    assert_equal 0, svc.flowdock.chats.count
    assert_equal 1, svc.flowdock.inbox.count
    assert_equal true, !!(svc.flowdock.inbox.first[:content] =~ /alert/)
    assert_equal true, !!(svc.flowdock.inbox.first[:content] =~ /r3.acme.com/)
    assert_equal true, !!(svc.flowdock.inbox.first[:content] =~ /r2.acme.com/)
  end

  def test_alerts
    svc = service(:alert, {"api_token" => "t", "user_name" => "Test"}.with_indifferent_access, alert_payload)
    svc.flowdock = MockFlowdock.new
    svc.receive_alert

    assert_equal 0, svc.flowdock.chats.count
    assert_equal 1, svc.flowdock.inbox.count
    assert_equal true, !!(svc.flowdock.inbox.first[:content] =~ /alert/)
  end

  def test_snapshots
    svc = service(:snapshot, {"api_token" => "t"}.with_indifferent_access, snapshot_payload)
    svc.flowdock = MockFlowdock.new
    svc.receive_snapshot

    assert_equal 2, svc.flowdock.chats.count
    assert_equal 0, svc.flowdock.inbox.count
    assert_equal true, !!(svc.flowdock.chats[0][:content] =~ /#{snapshot_payload[:snapshot][:entity_name]}/)
    assert_equal true, !!(svc.flowdock.chats[1][:content] =~ /http/)
  end

  def service(*args)
    super Service::Flowdock, *args
  end
end

