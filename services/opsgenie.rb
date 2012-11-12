class Service::OpsGenie < Service
        def receive_validate(errors)
                success = true
                [:name, :customerKey, :recipients].each do |k|
                        if settings[k].to_s.empty?
                                errors[k] = "Is required"
                                success = false
                        end
                end
                success
        end

        def receive_alert
                raise_config_error unless receive_validate({})
				
                message = "[Librato Metrics] Metric #{payload[:metric][:name]} value: #{payload[:measurement][:value]} has triggered an alert!"
                
                details = {
                        :"Alert Id" => payload[:alert][:id],
                        :"Alert Name" => payload[:alert][:name],
                        :Metric => payload[:metric][:name],
                        :"Measurement Value"=> payload[:measurement][:value],
                        :"Triggered At" => Time.at(payload[:trigger_time]).utc,
                        :"Measurement Source" => payload[:measurement][:source],
                        :"Metric Link" => metric_link(payload[:metric][:type],payload[:metric][:name])
                }
				
                params = {
                  :customerKey => settings[:customerKey],
                  :recipients => settings[:recipients],
                  :message => message,
                  :source => "Librato",
                  :details => details
                }

                url = "https://api.opsgenie.com/v1/json/alert"
                http_post url, params, 'Content-Type' => 'application/json'
        end
end

