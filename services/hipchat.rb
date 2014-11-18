require 'hipchat'
require 'timeout'

class Service::Hipchat < Service
  attr_writer :hipchat

  # Required parameters:
  #
  # auth_token: API Auth Token that supports notifications, see
  #             https://pipewise.hipchat.com/admin/api
  # from: Name the message should appear from
  # room_id: Id or name of the room
  # notify: Whether or not this message should trigger a notification
  #         for people in the room (0 | 1)
  def receive_validate(errors = {})
    [:auth_token, :from, :room_id, :notify].each do |k|
      errors[k] = "Is required" if settings[k].to_s.empty?
    end

    errors.empty?
  end

  def receive_alert_clear
    receive_alert
  end

  def receive_alert
    raise_config_error unless receive_validate({})
    if payload[:alert][:version] == 2
      format = 'text'
    else
      format = 'html'
    end
    send_message(alert_message, format)
  end

  def receive_snapshot
    raise_config_error unless receive_validate({})

    send_message(snapshot_message, 'html')
  end

  def alert_message
    link = payload_link(payload)

    # New-style alerts
    if payload[:alert][:version] == 2
      output = Librato::Services::Output.new(payload)
      return output.markdown
    end
    # Old-style alerts
    # grab the first 20 measurements
    measurements = get_measurements(payload)[0..19]
    if measurements.size == 1
      src = measurements[0][:source]
      "Alert triggered at %s for '%s' with value %f%s: <a href=\"%s\">%s</a>" %
        [
          Time.at(payload[:trigger_time]).utc,
          payload[:metric][:name],
          measurements[0][:value],
          src == "unassigned" ? "" : " from #{src}",
          link,
          link
        ]
    else
      # paste time
      message = "Alert triggered at %s for '%s'. Measurements:" %
        [
          Time.at(payload[:trigger_time]).utc,
          payload[:metric][:name]
        ]
      message << "\n"
      measurements = measurements.map do |m|
        if m["source"] == "unassigned"
          "  %f" % [m[:value]]
        else
          "  %s: %f" % [m[:source], m[:value]]
        end
      end
      message << measurements.join("\n")
      message
    end
  end

  def snapshot_message
    "%s: <a href=\"%s\">%s</a><br/><a href=\"%s\" target=\"_blank\"><img src=\"%s\"></img></a>" %
      [payload[:snapshot][:entity_name],
       payload[:snapshot][:entity_url],
       payload[:snapshot][:entity_url],
       payload[:snapshot][:image_url],
       payload[:snapshot][:image_url]]
  end

  def hipchat
    @hipchat ||= HipChat::Client.new(settings[:auth_token], :api_version => 'v1')
  end

  def send_message(msg, format)
    retries = 0
    begin
      success = hipchat[settings[:room_id]].send(settings[:from], msg,
                                           :notify => settings[:notify].to_i,
                                           :color => 'yellow',
                                           :message_format => format)
      raise Exception unless success == true
    rescue Timeout::Error => timeout
      retries += 1
      if retries > 3
        raise timeout
      end
      retry
    end
  end
end
