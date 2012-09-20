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
    if errors.empty?
      status_code = validate_settings(settings)
      if status_code == 401
        errors[:auth_token] = "Invalid Auth Token"
      elsif status_code == 404
        errors[:room_id] = "Invalid Room Id"
      end
    end
    errors.empty?
  end

  def receive_alert
    send_message(settings, generate_message(payload))
  end

  def validate_settings(settings)
    send_message(settings, "Test message from Librato Hipchat integration").status
  end

  def generate_message(payload)
    source = payload[:measurement][:source]
    link = metric_link(payload[:metric][:type], payload[:metric][:name])
    "Alert triggered at %s for '%s' with value %f%s: <a href=\"%s\">%s</a>" %
      [Time.at(payload[:trigger_time]).utc,
       payload[:metric][:name],
       payload[:measurement][:value],
       source == "unassigned" ? "" : " from #{source}",
       link, link]
  end

  def send_message(settings, message)
    # API Documentation https://www.hipchat.com/docs/api/method/rooms/message
    http_post hipchat_url(settings, message), {}, 'Content-Type' => 'application/json'
  end

  def hipchat_url(settings, message)
    encoded_message = URI.escape(message)
    "https://api.hipchat.com/v1/rooms/message?auth_token=#{settings[:auth_token]}&room_id=#{settings[:room_id]}&from=#{settings[:from]}&notify=#{settings[:notify]}&message=#{encoded_message}"
  end
end
