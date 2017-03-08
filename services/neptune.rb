# encoding: utf-8

require 'cgi'
require 'faraday'
require 'yajl'

class Service::Neptune < Service
  def receive_validate(errors = {})
    # Only api_key is required.
    if settings[:api_key].to_s.empty?
      errors[:api_key] = "Is required"
      return false
    end

    return true
  end

  def account_email
    if payload['auth']
      payload['auth']['email']
    end
  end

  def receive_alert_clear
    receive_alert
  end

  def receive_alert
    raise_config_error unless receive_validate({})

    # Keep the body similar to webhook service
    if payload[:alert][:version] == 2
      result = {
        :alert => payload['alert'],
        :account => account_email,
        :trigger_time => payload['trigger_time'],
        :conditions => payload['conditions'],
        :violations => payload['violations'],
        :triggered_by_user_test => payload['triggered_by_user_test']
      }

      result[:type] = payload[:clear] ? "resolve" : "trigger"

      # Set incident_key if it's present.
      result[:incident_key] = payload['incident_key'] if payload['incident_key']
    else
      measurements = get_measurements(payload)[0..19]
      result = {
        :alert => payload['alert'],
        :metric => payload['metric'],
        :measurement => measurements[0],
        :measurements => measurements,
        :trigger_time => payload['trigger_time']
      }
    end

    send_alert(result)
  end

  def headers
    {'Content-Type'  => 'application/json'}
  end

  def send_alert(body)
    api_key = settings[:api_key].to_s
    url = "https://www.neptune.io/api/v1/trigger/channel/librato/#{api_key}"
    begin
      http_post(url, {:payload => Yajl::Encoder.encode(body)}, headers)
    rescue Faraday::Error::ConnectionFailed
      log("Connection failed for url: #{url} for payload: #{payload.inspect}")
    end
  end

  def log(msg)
    if defined?(Rails)
      Rails.logger.info(msg)
    else
      puts(msg)
    end
  end
end 
