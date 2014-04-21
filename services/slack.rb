# encoding: utf-8

require 'uri'
require 'cgi'

class Service::Slack < Service
  def receive_validate(errors = {})
    success = true
    [:subdomain, :token].each do |k|
      if settings[k].to_s.empty?
        errors[k] = "Is required"
        success = false
      end
    end
    success
  end

  def v1_alert_result
    source = payload[:measurement][:source]
    link = metric_link(payload[:metric][:type], payload[:metric][:name])
    text = "Alert triggered for '<%s|%s>' with value %f%s" %
      [link,
       payload[:metric][:name],
       payload[:measurement][:value],
       source == "unassigned" ? "" : " from #{source}"]

    {
      :fallback => text,
      :attachments => [
        {
          :pretext => "Alert triggered",
          :fields => [
            {
              :title => "Metric",
              :value => "<%s|%s>" % [link, payload[:metric][:name]],
              :short => true
            },
            {
              :title => "Measurement Value",
              :value => payload[:measurement][:value],
              :short => true
            },
            {
              :title => "Measurement Source",
              :value => source,
              :short => true
            }
          ]
        }
      ],
      :channel => settings[:channel] == "" ? "" : settings[:channel],
      :username => username
    }
  end

  def v2_alert_result
    output = Librato::Services::Output.new(payload)
    {
      :text => output.markdown,
      :username => username
    }
  end

  def receive_alert
    raise_config_error unless receive_validate({})

    result = if payload[:alert][:version] == 2
      v2_alert_result
    else
      v1_alert_result
    end

    uri = URI.parse(slack_url)
    url = "%s://%s:%d%s" % [uri.scheme, uri.host, uri.port, uri.request_uri]

    http_post url, {:payload => Yajl::Encoder.encode(result)}
  rescue Faraday::Error::ConnectionFailed
    raise_error "Connection refused — invalid URL."
  end

  def username
    (settings[:username] && settings[:username] != '') ? settings[:username] : "Librato Alerts"
  end

  def slack_url
    "https://%s.slack.com/services/hooks/incoming-webhook?token=%s" % [settings[:subdomain], settings[:token]]
  end
end
