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

  def payload
    Librato::Services::Helpers::AlertHelpers.sample_payload
  end
end

