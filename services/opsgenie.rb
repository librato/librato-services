# encoding: utf-8

require 'uri'
require 'cgi'
require 'yajl'
require 'faraday'

class Service::OpsGenie < Service
  def receive_validate(errors)
    success = true
    [:api_key ].each do |k|
      if settings[k].to_s.empty?
        errors[k] = "Is required"
        success = false
      end
    end
    success
  end

  def receive_alert_clear
    raise_config_error unless receive_validate({})

    result = {
        :alert => payload['alert'],
        :trigger_time => payload['trigger_time'],
        :clear => "normal"
    }
    post_it(result)
  end

  def receive_alert
    raise_config_error unless receive_validate({})

    if payload[:alert][:version] == 2
      result = {
          :alert => payload['alert'],
          :trigger_time => payload['trigger_time'],
          :conditions => payload['conditions'],
          :violations => payload['violations']
      }
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

    post_it(result)
  end

  def post_it(hash)
    url = "https://api.opsgenie.com/v1/json/librato"
    http_post url, {
                     :apiKey => settings[:api_key],
                     :payload => Yajl::Encoder.encode(hash),
                     :recipients => settings[:recipients],
                     :teams => settings[:teams],
                     :tags => settings[:tags]
                 }
  rescue Faraday::Error::ConnectionFailed
    log("Connection failed for url: #{url} for payload: #{payload.inspect}")
  end

  def log(msg)
    if defined?(Rails)
      Rails.logger.info(msg)
    else
      puts(msg)
    end
  end
end
