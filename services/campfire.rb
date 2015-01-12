# encoding: utf-8

require 'tinder'

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

    speak_msgs(snapshot_message)
  end

  def snapshot_message
    snapshot = payload[:snapshot]

    # Make sure that spaces in the URI's are encoded.
    # We can't just call URI.escape, because escaping
    # an escaped URI is not idempotent. It will re-escape
    # the '%' signs from the first escaping
    uri = snapshot[:entity_url].gsub(/ /, '%20')

    # Campfire can't handle URI's that end in an '*'
    # because RACECARS :-/
    uri.gsub!(/\*$/, '%2A')

    # Chart name isn't required, show URL if absent
    name = snapshot[:entity_name] ? "#{snapshot[:entity_name]}: " : ''

    [
      "#{name} #{uri} by #{snapshot[:user_email]}",
      snapshot[:message],
      snapshot[:image_url]
    ].compact
  end

  def receive_alert_clear
    output = Librato::Services::Output.new(payload)
    paste_message output.markdown
  end

  def receive_alert
    raise_config_error unless receive_validate({})

    # New-style alerts
    if payload[:alert][:version] == 2
      output = Librato::Services::Output.new(payload)
      paste_message output.markdown
      return
    end

    # Old-style alerts
    # grab the first 20 measurements
    measurements = get_measurements(payload)[0..19]
    if measurements.size == 1
      src = measurements[0][:source]
      message = "Alert triggered at %s for '%s' with value %f%s: %s" %
        [
          Time.at(payload[:trigger_time]).utc,
          payload[:metric][:name],
          measurements[0][:value],
          src == "unassigned" ? "" : " from #{src}",
          metric_link(payload[:metric][:type], payload[:metric][:name])
        ]
      speak_msgs [message]
    else
      # paste time
      message = "Alert triggered at %s for %s:" %
        [
          Time.at(payload[:trigger_time]).utc,
          metric_link(payload[:metric][:type], payload[:metric][:name])
        ]
      speak_msgs [message]
      message = "'%s' measurements:\n" % [payload[:metric][:name]]
      measurements = measurements.map do |m|
        if m["source"] == "unassigned"
          "  %f" % [m[:value]]
        else
          "  %s: %f" % [m[:source], m[:value]]
        end
      end
      message << measurements.join("\n")
      paste_message message
    end
  end

  def speak_msgs(msgs)
    unless room = find_room
      puts "Warning: no such campfire room: #{settings[:room]}"
      return
    end
    msgs.each {|msg| room.speak msg }
  end

  def paste_message(msg)
    unless room = find_room
      puts "Warning: no such campfire room: #{settings[:room]}"
      return
    end
    room.paste msg
  end

  def campfire_hostname
    subdomain = settings[:subdomain].to_s
    subdomain.to_s[/^(.+?)(\.campfirenow\.com)?$/, 1]
  end

  def campfire
    @campfire ||= Tinder::Campfire.new(campfire_hostname, :token => settings[:token])
  rescue Tinder::AuthenticationFailed => e
    raise_error 'Authentication failed — invalid token'
  end

  def find_room
    campfire.find_room_by_name(settings[:room])
  end
end
