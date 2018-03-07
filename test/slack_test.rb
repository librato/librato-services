require File.expand_path('../helper', __FILE__)

module Librato::Services
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

      # the space in this case is invalid
      svc = service(:alert, @settings.merge(:url => 'https://sla ck.com/services/hooks/slackbot?token=test_token&test=true'), new_alert_payload)
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
        assert_equal "Alert <https://metrics.librato.com/alerts/123|Some alert name> has cleared at Sat, May 23 1970 at 14:32:03 UTC", attachment["text"]
        assert_equal "Alert 'Some alert name' has cleared at Sat, May 23 1970 at 14:32:03 UTC", attachment["fallback"]
        [200, {}, '']
      end
      svc.receive_alert
    end

    def test_v2_custom_alert_clear_unknown
      payload = new_alert_payload.dup
      payload[:clear] = "dont know"
      svc = service(:alert, @settings, payload)
      @stubs.post @stub_url do |env|
        payload = JSON.parse(env[:body])
        assert_not_nil(payload["attachments"])
        assert_equal(1, payload["attachments"].length)
        attachment = payload["attachments"][0]
        assert_equal(["color", "fallback", "text"], attachment.keys.sort)
        assert_nil(payload["text"])
        assert_equal "Alert <https://metrics.librato.com/alerts/123|Some alert name> has cleared at Sat, May 23 1970 at 14:32:03 UTC", attachment["text"]
        assert_equal "Alert 'Some alert name' has cleared at Sat, May 23 1970 at 14:32:03 UTC", attachment["fallback"]
        [200, {}, '']
      end
      svc.receive_alert
    end

    def test_v2_custom_alert_clear_manual
      payload = new_alert_payload.dup
      payload[:clear] = "manual"
      svc = service(:alert, @settings, payload)
      @stubs.post @stub_url do |env|
        payload = JSON.parse(env[:body])
        assert_not_nil(payload["attachments"])
        assert_equal(1, payload["attachments"].length)
        attachment = payload["attachments"][0]
        assert_equal(["color", "fallback", "text"], attachment.keys.sort)
        assert_nil(payload["text"])
        assert_equal "Alert <https://metrics.librato.com/alerts/123|Some alert name> was manually cleared at Sat, May 23 1970 at 14:32:03 UTC", attachment["text"]
        assert_equal "Alert 'Some alert name' was manually cleared at Sat, May 23 1970 at 14:32:03 UTC", attachment["fallback"]
        [200, {}, '']
      end
      svc.receive_alert
    end

    def test_v2_custom_alert_clear_auto
      payload = new_alert_payload.dup
      payload[:clear] = "auto"
      svc = service(:alert, @settings, payload)
      @stubs.post @stub_url do |env|
        payload = JSON.parse(env[:body])
        assert_not_nil(payload["attachments"])
        assert_equal(1, payload["attachments"].length)
        attachment = payload["attachments"][0]
        assert_equal(["color", "fallback", "text"], attachment.keys.sort)
        assert_nil(payload["text"])
        assert_equal "Alert <https://metrics.librato.com/alerts/123|Some alert name> was automatically cleared at Sat, May 23 1970 at 14:32:03 UTC", attachment["text"]
        assert_equal "Alert 'Some alert name' was automatically cleared at Sat, May 23 1970 at 14:32:03 UTC", attachment["fallback"]
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
        assert (not include_test_alert_message?(attachment["pretext"]))
        [200, {}, '']
      end
      svc.receive_alert
    end

    def test_v2_test_alert_triggered_by_user
      alert_payload = new_alert_payload
      alert_payload[:triggered_by_user_test] = true
      svc = service(:alert, @settings, alert_payload)
      @stubs.post @stub_url do |env|
        payload = JSON.parse(env[:body])
        attachment = payload["attachments"][0]
        assert include_test_alert_message?(attachment["pretext"])
        [200, {}, '']
      end
      svc.receive_alert
    end

    def test_snapshots
      svc = service(:snapshot, @settings, snapshot_payload)

      @stubs.post @stub_url do |env|
        payload = JSON.parse(env[:body])
        original = snapshot_payload["snapshot"]
        assert(payload["attachments"][0]["title"].include?(original["entity_name"]))
        assert(payload["attachments"][0]["author_name"].include?(original["user"]["full_name"]))
        assert(payload["attachments"][0]["text"].include?(original["message"]))
        assert(payload["attachments"][0]["image_url"].include?(original["image_url"]))
        [200, {}, '']
      end

      svc.receive_snapshot
    end

    def test_author_name_with_full_name
      svc = service(:snapshot, @settings, snapshot_payload)

      @stubs.post @stub_url do |env|
        payload = JSON.parse(env[:body])
        assert_equal("Librato User", payload["attachments"][0]["author_name"])
        [200, {}, '']
      end

      svc.receive_snapshot
    end

    def test_author_name_without_full_name
      snapshot_payload_dup = snapshot_payload.dup
      snapshot_payload_dup["snapshot"]["user"].reject! { |k,_| k == "full_name" }
      svc = service(:snapshot, @settings, snapshot_payload_dup)

      @stubs.post @stub_url do |env|
        payload = JSON.parse(env[:body])
        assert_equal("portal-dev@librato.com", payload["attachments"][0]["author_name"])
        [200, {}, '']
      end

      svc.receive_snapshot
    end

    def service(*args)
      super Librato::Services::Service::Slack, *args
    end
  end
end
