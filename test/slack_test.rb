require File.expand_path('../helper', __FILE__)

class SlackTest < Librato::Services::TestCase
  def setup
    @settings = { :url => "https://example.com?token=foo" }
    @stub_url = URI.parse(@settings[:url]).request_uri
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_validations
    svc = service(:alert, @settings, new_alert_payload)
    errors = {}
    assert(svc.receive_validate(errors))
    assert_equal(0, errors.length)

    # the url is non-nil, but blank
    svc = service(:alert, @settings.merge(:url => ''), new_alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)

    # the '/' in the token in this case is invalid
    svc = service(:alert, @settings.merge(:url => 'https://slack.com/services/hooks/slackbot?token=test_token\&test=true'), new_alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)

    svc = service(:alert, {}, new_alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    assert(!errors[:url].nil?)
  end

  def test_v1_alerts
    svc = service(:alert, @settings, alert_payload)

    @stubs.post @stub_url do |env|
      raise 'should not fire'
      [200, {}, '']
    end

    assert_raises(Librato::Services::Service::ConfigurationError) { svc.receive_alert }
  end

  def test_v2_custom_alert_clear
    payload = new_alert_payload.dup
    payload[:clear] = "normal"
    svc = service(:alert, @settings, payload)
    @stubs.post @stub_url do |env|
      payload = JSON.parse(env[:body])
      assert_not_nil(payload["attachments"])
      assert_equal(1, payload["attachments"].length)
      attachment = payload["attachments"][0]
      assert_equal(["color", "fallback", "text"], attachment.keys.sort)
      assert_nil(payload["text"])
      [200, {}, '']
    end
    svc.receive_alert
  end

  def test_v2_custom_alerts
    svc = service(:alert, @settings, new_alert_payload)
    @stubs.post @stub_url do |env|
      payload = JSON.parse(env[:body])
      assert_not_nil(payload["attachments"])
      assert_equal(1, payload["attachments"].length)
      attachment = payload["attachments"][0]
      assert_not_nil(attachment["fallback"])
      assert_not_nil(attachment["color"])
      assert_not_nil(attachment["pretext"])
      assert_not_nil(attachment["fields"])
      assert_equal(1, attachment["fields"].length)
      assert_not_nil(attachment["mrkdwn_in"])
      [200, {}, '']
    end
    svc.receive_alert
  end

  def test_snapshots
    svc = service(:snapshot, @settings, snapshot_payload)
    mock_bytes = '175000'

    @stubs.head URI.parse(snapshot_payload["snapshot"]["image_url"]).path do |env|
      [200, {'Content-Length' => mock_bytes}, '']
    end

    @stubs.post @stub_url do |env|
      payload = JSON.parse(env[:body])
      original = snapshot_payload["snapshot"]
      assert_equal(original["entity_name"], payload["inst_text"])
      assert_equal(original["entity_url"], payload["inst_url"])
      assert_equal(original["image_url"], payload["image_url"])
      assert_equal(Librato::Services::Helpers::SnapshotHelpers::DEFAULT_SNAPSHOT_WIDTH, payload["image_width"])
      assert_equal(Librato::Services::Helpers::SnapshotHelpers::DEFAULT_SNAPSHOT_HEIGHT, payload["image_height"])
      assert_equal(mock_bytes, payload["image_bytes"])
      [200, {}, '']
    end

    svc.receive_snapshot
  end

  def service(*args)
    super Service::Slack, *args
  end
end
