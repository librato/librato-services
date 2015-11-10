require 'rubygems'
require 'bundler'

Bundler.require

$:.unshift(File.join(File.dirname(__FILE__), '../lib'))
require 'librato-services'

require 'test/unit'

class Librato::Services::TestCase < Test::Unit::TestCase
  def test_default
  end

  def service(klass, event_or_data, data, payload=nil)
    event = nil
    if event_or_data.is_a?(Symbol)
      event = event_or_data
    else
      payload = data
      data    = event_or_data
      event   = :alert
    end

    service = klass.new(event, data, payload)
    service.http = Faraday.new do |b|
      b.adapter :test, @stubs
    end
    service
  end

  def basic_auth(user, pass)
    "Basic " + ["#{user}:#{pass}"].pack("m*").strip
  end

  def new_alert_payload
    Librato::Services::Helpers::AlertHelpers.sample_new_alert_payload
  end

  def alert_payload_multiple_measurements
    Librato::Services::Helpers::AlertHelpers.sample_alert_payload_multiple_measurements
  end

  def alert_payload
    Librato::Services::Helpers::AlertHelpers.sample_alert_payload
  end

  # Valid clear types : normal, auto, manual, unknown
  def alert_clear_payload(clear_type = 'normal')
    Librato::Services::Helpers::AlertHelpers.sample_alert_clear_payload(clear_type)
  end

  def snapshot_payload
    Librato::Services::Helpers::SnapshotHelpers.sample_snapshot_payload
  end

  def include_test_alert_message?(actual)
    actual.include? "This is a test alert notification, no action is required."
  end
end
