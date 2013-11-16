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

  def receive_alert
    raise_config_error unless receive_validate({})
    if settings[:recipients].to_s.empty?
      settings[:recipients] = "all"
    end

    measurements = payload[:measurements][0..19]
    if measurements.size == 1
      message = "[Librato Metrics] Metric #{payload[:metric][:name]} value: #{payload[:measurements][0][:value]} has triggered an alert!"
      details = {
        :"Alert Id" => payload[:alert][:id],
        :Metric => payload[:metric][:name],
        :"Measurement Value"=> payload[:measurements][0][:value],
        :"Triggered At" => Time.at(payload[:trigger_time]).utc,
        :"Measurement Source" => payload[:measurements][0][:source],
        :"Metric Link" => metric_link(payload[:metric][:type],payload[:metric][:name])
      }
    else
      message = "[Librato Metrics] Metric #{payload[:metric][:name]} has triggered an alert! Measurements:\n"
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
        :"Measurements"=> payload[:measurements].map { |m|
          m["source"] == "unassigned" ? "%f" % [m[:value]] : "%s: %f" % [m[:source],m[:value]]
        }.join(", "),
        :"Triggered At" => Time.at(payload[:trigger_time]).utc,
        :"Metric Link" => metric_link(payload[:metric][:type],payload[:metric][:name])
      }
    end


    details[:"Alert Name"] = payload[:alert][:name] if payload[:alert][:name]
    params = {
      :customerKey => settings[:customer_key],
      :recipients => settings[:recipients],
      :alias => payload[:metric][:name],
      :message => message,
      :source => "Librato",
      :details => details
    }
    url = "https://api.opsgenie.com/v1/json/alert"
    http_post url, params, 'Content-Type' => 'application/json'
  end
end

