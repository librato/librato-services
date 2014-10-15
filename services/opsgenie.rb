class Service::OpsGenie < Service
  def receive_validate(errors)
    success = true
    [:customer_key ].each do |k|
      if settings[k].to_s.empty?
        errors[k] = "Is required"
        success = false
      end
    end
    success
  end

  def receive_alert_clear
    raise_config_error unless receive_validate({})
    if settings[:recipients].to_s.empty?
      settings[:recipients] = "all"
    end
    trigger_time_utc = Time.at(payload[:trigger_time]).utc
    message = case payload[:clear]
              when "manual"
                "Alert #{payload[:alert][:name]} was manually cleared at #{trigger_time_utc}"
              when "auto"
                "Alert #{payload[:alert][:name]} was automatically cleared at #{trigger_time_utc}"
              else
                "Alert #{payload[:alert][:name]} has cleared at #{trigger_time_utc}"
              end
    do_post(payload[:alert][:name], message, payload)
    return
  end

  def receive_alert
    raise_config_error unless receive_validate({})
    if settings[:recipients].to_s.empty?
      settings[:recipients] = "all"
    end

    if payload[:alert][:version] == 2
      message = "Alert #{payload[:alert][:name]} has triggered!"
      payload = payload.dup
      payload.delete(:auth)
      payload.delete(:settings)
      do_post(payload[:alert][:name], message, payload)
      return
    end

    measurements = get_measurements(payload)[0..19]
    if measurements.size == 1
      message = "[Librato] Metric #{payload[:metric][:name]} value: #{measurements[0][:value]} has triggered an alert!"
      details = {
        :"Alert Id" => payload[:alert][:id],
        :Metric => payload[:metric][:name],
        :"Measurement Value"=> measurements[0][:value],
        :"Triggered At" => Time.at(payload[:trigger_time]).utc,
        :"Measurement Source" => measurements[0][:source],
        :"Metric Link" => metric_link(payload[:metric][:type],payload[:metric][:name])
      }
    else
      message = "[Librato] Metric #{payload[:metric][:name]} has triggered an alert! Measurements:\n"
      measurements.each do |m|
        if m["source"] == "unassigned"
          " %f" % [m[:value]]
        else
          " %s: %f" % [m[:source], m[:value]]
        end
      end
      details = {
        :"Alert Id" => payload[:alert][:id],
        :Metric => payload[:metric][:name],
        :"Measurements"=> measurements.map { |m|
          m["source"] == "unassigned" ? "%f" % [m[:value]] : "%s: %f" % [m[:source],m[:value]]
        }.join(", "),
        :"Triggered At" => Time.at(payload[:trigger_time]).utc,
        :"Metric Link" => metric_link(payload[:metric][:type],payload[:metric][:name])
      }
    end


    details[:"Alert Name"] = payload[:alert][:name] if payload[:alert][:name]
    do_post(payload[:metric][:name], message, details)
  end

  def do_post(name, message, details)
    message = message[0,130] # opsgenie allows max 130 chars
    params = {
      :customerKey => settings[:customer_key],
      :recipients => settings[:recipients],
      :alias => name,
      :source => "Librato",
      :details => details,
      :alias => payload[:incident_key]
    }
    if payload[:clear]
      url = "https://api.opsgenie.com/v1/json/alert/close"
      params[:note] = message
    else
      params[:message] = message
      url = "https://api.opsgenie.com/v1/json/alert"
    end
    http_post url, params, 'Content-Type' => 'application/json'
  end
end

