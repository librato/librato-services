# encoding: utf-8
class Service::Campfire < Service
  attr_writer :campfire

  def receive_validate(errors)
    [:token, :room].each do |k|
      errors.add(k, "Is required") if settings[k].to_s.empty?
    end
  end

  def receive_alert
    raise_config_error 'Missing campfire token' if settings[:token].to_s.empty?

    unless room = find_room
      raise_error 'No such campfire room'
    end

    message = %{"#{payload[:saved_search][:name]}" search found #{pluralize(payload[:events].length, 'match')} — #{payload[:saved_search][:html_search_url]}}
    paste = payload[:events].collect { |event| syslog_format(event) }.join("\n")

    play_sound = settings[:play_sound].to_i == 1

    room.speak message
    room.paste paste
    room.play "rimshot" if play_sound && room.respond_to?(:play)
  rescue Faraday::Error::ConnectionFailed
    raise_error "Connection refused — invalid campfire subdomain."
  end

private

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
