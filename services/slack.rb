# encoding: utf-8

require 'uri'
require 'cgi'
require 'digest'

class Service::Slack < Service
  VERTICAL_LINE_COLOR = "#0880ad"

  def receive_validate(errors = {})
    if settings[:url].blank?
      errors[:url] = "Is required"
      return false
    end
    begin
      URI.parse(settings[:url])
    rescue => e
      errors[:url] = "Is not valid"
      return false
    end
    true
  end

  def v2_alert_result
    data = Librato::Services::Output.new(payload)
    runbook_url = data.alert[:runbook_url]
    trigger_time_utc = DateTime.strptime(data.trigger_time.to_s, "%s").strftime("%a, %b %e %Y at %H:%M:%S UTC")
    if data.clear
      text = case data.clear
             when "manual"
              "Alert <#{alert_link(data.alert[:id])}|#{data.alert[:name]}> was manually cleared at #{trigger_time_utc}"
             when "auto"
               "Alert <#{alert_link(data.alert[:id])}|#{data.alert[:name]}> was automatically cleared at #{trigger_time_utc}"
             else
               "Alert <#{alert_link(data.alert[:id])}|#{data.alert[:name]}> has cleared at #{trigger_time_utc}"
             end
      fallback = case data.clear
                 when "manual"
                   "Alert '#{data.alert[:name]}' was manually cleared at #{trigger_time_utc}"
                 when "auto"
                   "Alert '#{data.alert[:name]}' was automatically cleared at #{trigger_time_utc}"
                 else
                   "Alert '#{data.alert[:name]}' has cleared at #{trigger_time_utc}"
                 end
      {
        :attachments => [
          {
            :text => text,
            :fallback => fallback,
            :color => "#17B03C"
          }
        ]
      }
    else
      pretext = ''
      if payload[:triggered_by_user_test]
        pretext << "#{test_alert_message()}\n\n"
      end
      pretext << "Alert <#{alert_link(data.alert[:id])}|#{data.alert[:name]}> has triggered!"
      unless runbook_url.blank?
        pretext << " <#{runbook_url}|Runbook>"
      end
      attachments = []
      attachment = {
        :fallback => format_fallback(data),
        :color => VERTICAL_LINE_COLOR,
        :pretext => pretext,
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
      attachments << attachment
      {
        :attachments => attachments
      }
    end
  end

  def url
    uri = URI.parse(settings[:url])
    "%s://%s:%d%s" % [uri.scheme, uri.host, uri.port, uri.request_uri]
  end

  def format_fallback(data)
    data.markdown.sub(/^#\s+/, '').                 # no leading #
      gsub('`', '\'').                              # no backticks
      chomp + " • #{alert_link(data.alert[:id])}\n" # add the alert link
  end

  def raise_url_error
    raise_error "Connection refused — invalid URL."
  end

  def receive_snapshot
    raise_config_error unless receive_validate({})

    http_post(url, snapshot_message)
  rescue Faraday::Error::ConnectionFailed
    raise_url_error
  end

  def snapshot_message
    snapshot = payload[:snapshot]

    name = snapshot[:entity_name].blank? ? snapshot[:entity_url] : snapshot[:entity_name]
    sender = snapshot[:user][:full_name].blank? ? snapshot[:user][:email] : snapshot[:user][:full_name]
    message = snapshot[:message].blank? ? nil : "#{snapshot[:message]}\n"
    gravatar = "https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest(snapshot[:user][:email])}?s=32&d=mm"

    data = {
      attachments: [
        {
          author_name: sender,
          author_link: "mailto:#{snapshot[:user][:email]}",
          author_icon: gravatar,
          title: name,
          title_link: snapshot[:entity_url],
          fallback: "#{name} by #{sender}: #{snapshot[:image_url]}",
          image_url: snapshot[:image_url],
          text: message,
          color: "#0881AE"
        }
      ]
    }

    Yajl::Encoder.encode(data)
  end

  def receive_alert_clear
    receive_alert
  end

  def receive_alert
    raise_config_error unless receive_validate({})
    result = if payload[:alert][:version] == 2
               v2_alert_result
             else
               raise_config_error('Slack does not support V1 alerts')
             end
    http_post(url, Yajl::Encoder.encode(result))
  rescue Faraday::Error::ConnectionFailed
    raise_url_error
  end

  def log(msg)
    Rails.logger.info(msg) if defined?(Rails)
  end
end
