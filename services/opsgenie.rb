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
         	  :payload => payload,
         	  :recipients => settings[:recipients]
        	}

                url = "https://api.opsgenie.com/v1/json/librato"
                http_post url, params, 'Content-Type' => 'application/json'
        end
end
