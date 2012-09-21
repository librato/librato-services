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

  def receive_snapshot
    raise_config_error unless receive_validate({})

    speak_msgs(["%s: %s" % [payload[:snapshot][:entity_name],
                            payload[:snapshot][:entity_url]],
                payload[:snapshot][:image_url]])
  end

  def receive_alert
    raise_config_error unless receive_validate({})

    src = payload[:measurement][:source]

    message = "Alert triggered at %s for '%s' with value %f%s: %s" %
      [Time.at(payload[:trigger_time]).utc,
       payload[:metric][:name],
       payload[:measurement][:value],
       src == "unassigned" ? "" : " from #{src}",
       metric_link(payload[:metric][:type], payload[:metric][:name])]

    speak_msgs [message]
  end

  def speak_msgs(msgs)
    unless room = find_room
      puts "Warning: no such campfire room: #{settings[:room]}"
      return
    end

    msgs.each {|msg| room.speak msg }
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
