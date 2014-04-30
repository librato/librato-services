# encoding: utf-8

require 'uri'
require 'cgi'

class Service::Slack < Service
  VERTICAL_LINE_COLOR = "#0880ad"

  def receive_validate(errors = {})
    unless settings[:url]
      errors[:url] = "Is required"
      return false
    end
    true
  end

  def v2_alert_result
    data = Librato::Services::Output.new(payload)
    {
      :attachments => [
        {
          :fallback => format_fallback(data),
          :color => VERTICAL_LINE_COLOR,
          :pretext => "Alert <#{alert_link(data.alert[:id])}|#{data.alert[:name]}> has triggered!",
          :fields => data.violations.map do |source, measurements|
            {
              :title => source,
              :value => measurements.inject([]) do |texts, measurement|
                texts << data.format_measurement(measurement)
              end.join("\n")
            }
          end,
          :mrkdwn_in => [:text, :fields]
        }
      ]
    }
  end

  def format_fallback(data)
    data.markdown.sub(/^#\s+/, '').                 # no leading #
      gsub('`', '\'').                              # no backticks
      chomp + " • #{alert_link(data.alert[:id])}\n" # add the alert link
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
