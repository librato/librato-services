# encoding: utf-8

require 'uri'
require 'cgi'

class Service::Slack < Service
  # transitional
  # Branch "gemify" has different, required settings
  def receive_validate(errors = {}); true; end

  def receive_alert
    raise_config_error unless receive_validate({})

    uri = URI.parse(slack_url)

    source = payload[:measurement][:source]
    link = metric_link(payload[:metric][:type], payload[:metric][:name])
    text = "Alert triggered for '<%s|%s>' with value %f%s" %
      [link,
       payload[:metric][:name],
       payload[:measurement][:value],
       source == "unassigned" ? "" : " from #{source}"]

    result = {
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
      :username => settings[:username] == "" ? "" : settings[:username]
    }

    url = "%s://%s:%d%s" % [uri.scheme, uri.host, uri.port, uri.request_uri]

    http_post url, {:payload => Yajl::Encoder.encode(result)}
  rescue Faraday::Error::ConnectionFailed
    raise_error "Connection refused — invalid URL."
  end

  def slack_url
    "https://%s.slack.com/services/hooks/incoming-webhook?token=%s" % [settings[:subdomain], settings[:token]]
  end
end
