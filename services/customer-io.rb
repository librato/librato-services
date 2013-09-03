# encoding: utf-8
#
# Integration with the Customer.io service, which will trigger an event being
# sent when an alert occurs. This requires that your source name be of the format
# "uid:123", where 123 is the customer.io customer id to event upon.
class Service::CustomerIo < Service
  attr_writer :client

  def receive_validate(errors = {})
    [:site_id, :api_key, :event_name].any? { |k|
      settings[k].to_s.empty? && errors[k] = "Is required"
    }
  end

  def receive_alert
    client.track(user_id, event_name, payload)
  end

  def user_id
    id = payload[:measurement][:source].split(':').last
    return if id.nil? || id !~ /\d+/
    Integer(id)
  end

  def event_name
    settings[:event_name]
  end

  def client
    @client ||= Customerio::Client.new(settings[:site_id], settings[:api_key])
  end

end

