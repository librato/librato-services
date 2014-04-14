require 'json'

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

                params = {
         	  :apiKey => settings[:customer_key],
         	  
         	  :alertId => payload[:alert][:id],
         	  :alertName => payload[:alert][:name],
         	  
         	  :metricName => payload[:metric][:name],
         	  :metricType => payload[:metric][:type],
         	  
         	  :measurementValue => payload[:measurement][:value],
         	  :measurementSource => payload[:measurement][:source],

         	  :measurements => JSON.toJson(payload[:measurements]),
         	  
         	  :metricLink => payload[:metric_link],
         	  :triggerTime => payload[:trigger_time],
         	  :recipients => settings[:recipients]
        	}

                url = "https://api.opsgenie.com/v1/json/librato"
                http_post url, params, 'Content-Type' => 'application/json'
        end
end
