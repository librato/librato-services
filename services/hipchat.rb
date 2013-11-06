require 'hipchat-api'

class Service::Hipchat < Service

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

  def receive_alert
    raise_config_error unless receive_validate({})

    send_message(alert_message)
  end

  def receive_snapshot
    raise_config_error unless receive_validate({})

    send_message(snapshot_message)
  end

  def alert_message
    source = payload[:measurement][:source]
    link = metric_link(payload[:metric][:type], payload[:metric][:name])
    "Alert triggered at %s for '%s' with value %f%s: <a href=\"%s\">%s</a>" %
      [Time.at(payload[:trigger_time]).utc,
       payload[:metric][:name],
       payload[:measurement][:value],
       source == "unassigned" ? "" : " from #{source}",
       link, link]
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
    @hipchat ||= HipChat::API.new(settings[:auth_token])
  end

  def send_message(msg)
    hipchat.rooms_message(settings[:room_id], settings[:from], msg,
                         settings[:notify].to_i, 'yellow', 'html')
  end
end
