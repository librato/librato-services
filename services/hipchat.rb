require 'hipchat'
require 'timeout'
require 'uri'

module Librato::Services
  class Service::Hipchat < Librato::Services::Service
    attr_writer :hipchat

    # Required parameters:
    #
    # auth_token: API Auth Token that supports notifications, see
    #             https://pipewise.hipchat.com/admin/api
    # from: Name the message should appear from (max 15 chars),
    #         can only contain letters, numbers, ., -, _, and spaces
    # room_id: Id or name of the room
    # notify: Whether or not this message should trigger a notification
    #         for people in the room (0 | 1)
    # server_url: Server URL for HipChat service, defaults to 'https://api.hipchat.com'

    def receive_validate(errors = {})

      # check for existence
      [:auth_token, :from, :room_id, :notify].each do |k|
        errors[k] = "Is required" if settings[k].to_s.empty?
      end

      # check length of :from
      if !settings[:from].nil?
        errors[:from] = "length is too long, max 15 characters" if settings[:from].length > 15
      end

      # check for approved char classes for :from
      if !settings[:from].nil?
        errors[:from] = "string has invalid characters" if /^[\w\s\.\-\_]+$/.match(settings[:from]).nil?
      end

      # check that notify is boolean
      if !settings[:notify].nil?
        errors[:notify] = "must be a 0 or 1" unless ['0', '1'].include?(settings[:notify])
      end

      # check basic syntax for server_url
      if !settings[:server_url].nil?
        begin
          URI.parse settings[:server_url]
        rescue URI::InvalidURIError
          errors[:server_url] = "is invalid"
        end
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
      snapshot = payload[:snapshot]

      name = snapshot[:entity_name].blank? ? snapshot[:entity_url] : snapshot[:entity_name]
      sender = snapshot[:user][:full_name].blank? ? snapshot[:user][:email] : snapshot[:user][:full_name]
      message = snapshot[:message].blank? ? nil : "<br/>#{snapshot[:message]}"

      [
       "<a href='#{snapshot[:entity_url]}'>#{name}</a> by #{sender}",
       message,
       "<br/><a href='#{snapshot[:image_url]}' target='_blank'><img src='#{snapshot[:image_url]}'></img></a>"
      ].compact.join
    end

    def server_url
      settings[:server_url] || 'https://api.hipchat.com'
    end

    def hipchat
      @hipchat ||= HipChat::Client.new(settings[:auth_token], :api_version => 'v1', :server_url => server_url)
    end

    def send_message(msg, format)
      retries = 0
      begin
        success = hipchat[settings[:room_id]].send(settings[:from], truncate(msg),
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

    private

    # Prevent messages over 10,000 characters from causing a 400 error
    # See: https://www.hipchat.com/docs/api/method/rooms/message
    def truncate(message)
      if message.length > 10_000
        message[0...9985] << "... (truncated)"
      else
        message
      end
    end
  end
end
