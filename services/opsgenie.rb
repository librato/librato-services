class Service::OpsGenie < Service
        def receive_validate(errors)
                success = true
                [:name, :customer_key ].each do |k|
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
				
                message = "[Librato Metrics] Metric #{payload[:metric][:name]} value: #{payload[:measurement][:value]} has triggered an alert!"
                
                details = {
                        :"Alert Id" => payload[:alert][:id],
                        :Metric => payload[:metric][:name],
                        :"Measurement Value"=> payload[:measurement][:value],
                        :"Triggered At" => Time.at(payload[:trigger_time]).utc,
                        :"Measurement Source" => payload[:measurement][:source],
                        :"Metric Link" => metric_link(payload[:metric][:type],payload[:metric][:name])
                }

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

