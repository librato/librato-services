# TODO: fix for new-style alerts
# encoding: utf-8
#
# Integration with the Customer.io service, which will trigger an event being
# sent when an alert occurs. This requires that your source name be of the format
# "uid:123", where 123 is the customer.io customer id to event upon.

require 'customerio'

class Service::CustomerIo < Service
  attr_writer :client

  def receive_validate(errors = {})
    [:site_id, :api_key, :event_name].any? { |k|
      settings[k].to_s.empty? && errors[k] = "Is required"
    }
  end

  def receive_alert
    if payload[:alert][:version] == 2
      payload[:violations].each do |source, violations|
        source_data = extract_data_from_source(source)
        user_id = source_data["uid"]
        event_data = violations.first.merge(source_data)
        log "customer.io event %s uid:%i %s" % [event_name, user_id, event_data.inspect]
        client.track(user_id, event_name, event_data)
      end
    else
      get_measurements(payload).each do |measurement|
        pd = payload.dup
        pd[:measurement] = measurement
        source_data = extract_data_from_source(measurement[:source])
        user_id = source_data["uid"]
        event_data = source_data.merge(pd)
        log "customer.io event %s uid:%i %s" % [event_name, user_id, event_data.inspect]
        client.track(user_id, event_name, event_data)
      end
    end
  end

  def extract_data_from_source(source)
    {}.tap do |data|
      source.split(".").each do |segment|
        k, v = segment.split(":")
        v = Integer(v) if v =~ /^\d+$/
        data[k] = v
      end
    end.with_indifferent_access
  end

  def get_user_id_from_string(str)
    id = str.split(':').last
    return if id.nil? || id !~ /\d+/
    Integer(id)
  end

  def get_user_id(measurement)
    get_user_id_from_string(measurement[:source])
  end

  def event_name
    settings[:event_name]
  end

  def client
    @client ||= Customerio::Client.new(settings[:site_id], settings[:api_key])
  end

  def log(msg)
    Rails.logger.info(msg) if defined?(Rails)
  end

end

