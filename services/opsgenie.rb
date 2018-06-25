# encoding: utf-8

require 'uri'
require 'cgi'
require 'yajl'
require 'faraday'

module Librato::Services
  class Service::OpsGenie < Librato::Services::Service
    def receive_validate(errors)
      success = true
      [:customer_key ].each do |k|
        if settings[k].to_s.empty?
          errors[k] = "Is required"
          success = false
        end
      end
      success
    end

    def account_email
      if payload['auth']
        payload['auth']['email']
      end
    end

    def receive_alert_clear
      raise_config_error unless receive_validate({})

      result = {
        :alert => payload['alert'],
        :account => account_email,
        :trigger_time => payload['trigger_time'],
        :clear => "normal"
      }
      post_it(result, false)
    end

    def receive_alert
      raise_config_error unless receive_validate({})

      if payload[:alert][:version] == 2
        result = {
          :alert => payload['alert'],
          :account => account_email,
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
      post_it(result, payload[:triggered_by_user_test])
    end

    def post_it(hash, triggered_by_user_test)
      tags = settings[:tags].nil? ?  "" : settings[:tags].dup
      if triggered_by_user_test
        tags += tags.empty? ? "triggered_by_user_test" : ",triggered_by_user_test"
      end
      http_post url, {
        :apiKey => settings[:customer_key],
        :payload => Yajl::Encoder.encode(hash),
        :recipients => settings[:recipients],
        :teams => settings[:teams],
        :tags => tags
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

    def url
      begin
        uri = URI.parse("https://api.opsgenie.com/v1/json/librato")
        if hostname = settings[:hostname]
          uri.host = hostname
        end

        uri.to_s
      rescue StandardError => e
        raise_config_error(e.message)
      end
    end
  end
end
