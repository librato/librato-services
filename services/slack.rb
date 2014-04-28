# encoding: utf-8

require 'uri'
require 'cgi'

class Service::Slack < Service
  def receive_validate(errors = {})
    unless settings[:url]
      errors[:url] = "Is required"
      return false
    end
    true
  end

  def v2_alert_result
    output = Librato::Services::Output.new(payload)
    {
      :alert_text => output.markdown,
      :alert_url => alert_link(payload[:alert][:id])
    }
  end

  def receive_alert
    raise_config_error unless receive_validate({})

    result = if payload[:alert][:version] == 2
      v2_alert_result
    else
      raise_config_error('Slack does not support V1 alerts')
    end

    uri = URI.parse(settings[:url])
    url = "%s://%s:%d%s" % [uri.scheme, uri.host, uri.port, uri.request_uri]

    http_post(url, Yajl::Encoder.encode(result))
  rescue Faraday::Error::ConnectionFailed
    raise_error "Connection refused — invalid URL."
  end
end
