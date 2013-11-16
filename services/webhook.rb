# encoding: utf-8

require 'uri'
require 'cgi'

class Service::Webhook < Service
  def receive_validate(errors = {})
    if settings[:url].to_s.empty?
      errors[:url] = "Is required"
      return false
    end

    uri = URI.parse(settings[:url]) rescue nil
    unless uri
      errors[:url] = "Is not a valid URL"
      return false
    end

    return true
  end

  def receive_alert
    raise_config_error unless receive_validate({})

    uri = URI.parse(settings[:url])

    result = {
      :alert => payload['alert'],
      :metric => payload['metric'],
      :measurement => payload['measurements'][0],
      :measurements => payload['measurements'],
      :trigger_time => payload['trigger_time']
    }

    # Faraday doesn't unescape user and password
    if uri.userinfo
      http.basic_auth *uri.userinfo.split(":").map{|x| CGI.unescape(x)}
    end

    url = "%s://%s:%d%s" % [uri.scheme, uri.host, uri.port, uri.request_uri]

    http_post url, {:payload => Yajl::Encoder.encode(result)}
  rescue Faraday::Error::ConnectionFailed
    raise_error "Connection refused — invalid URL."
  end
end
