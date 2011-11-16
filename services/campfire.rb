# encoding: utf-8
class Service::Campfire < Service
  attr_writer :campfire

  def receive_validate(errors = {})
    success = true
    [:subdomain, :token, :room].each do |k|
      if settings[k].to_s.empty?
        errors[k] = "Is required"
        success = false
      end
    end
    success
  end

  def receive_alert
    # XXX: should run receive_validate()
    raise_config_error unless receive_validate({})

    unless room = find_room
      raise_error 'No such campfire room'
    end

    src = payload[:measurement][:source]

    message = "Alert triggered at %s for '%s' with value %f%s: %s" %
      [Time.at(payload[:trigger_time]).utc,
       payload[:metric][:name],
       payload[:measurement][:value],
       src == "unassigned" ? "" : " from #{src}",
       metric_link(payload[:metric][:type], payload[:metric][:name])]

    #paste = %{Payload: #{payload.inspect}}
    #play_sound = settings[:play_sound].to_i == 1

    room.speak message
    #room.paste paste
    #room.play "rimshot" if play_sound && room.respond_to?(:play)
  rescue Faraday::Error::ConnectionFailed
    raise_error "Connection refused — invalid campfire subdomain."
  end

  def campfire_hostname
    settings[:subdomain].to_s[/^(.+)(\.campfirenow\.com)?$/, 1]
  end

  def campfire
    @campfire ||= Tinder::Campfire.new(campfire_hostname, :token => settings[:token])
  rescue Tinder::AuthenticationFailed => e
    raise_error 'Authentication failed — invalid token'
  end

  def find_room
    room = campfire.find_room_by_name(settings[:room])
  rescue StandardError
  end
end
