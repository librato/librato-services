require 'uri'

class Service::VictorOps < Service
  REQUIRED_SETTING_KEYS = [:api_key]

  def receive_validate(errors = {})
    REQUIRED_SETTING_KEYS.inject(true) do |previous_passed, key|
      key_found = !settings[key].to_s.empty?
      errors[:name] = "Not found" unless key_found
      previous_passed && key_found
    end
  end

  def receive_alert
    body = settings.merge(flatten_hash(payload))
    body.delete :api_key

    # Keys that will soon be in the payload
    body[:entity_id] = payload[:incident_key] || payload['alert']['id']
    body[:clear] = payload[:clear] if payload[:clear]

    # Fire
    uri = uri_for_key(settings[:api_key])
    http_post(uri, body, headers)
  end

  def settings
    @settings.merge({
      monitoring_tool: 'librato'
    })
  end

  private

  def flatten_hash(payload)
    {
      state_message: payload['alert']['name'] || 'No Alert Name Provided',
      metric_name: payload['metric']['name'],
      metric_type: payload['metric']['type'],
      measurment_name: payload['measurement']['value'],
      measurment_source: payload['measurement']['source']
    }
  end

  def alert_for_type(type)
    {
      message_type: type,
      entity_id: null,
    }
  end

  # Helpers
  def uri_for_key(key)
    File.join("#{http_scheme}#{host}", integrations_path_for_key(key), (settings[:routing_key] || 'nil')).to_s
  end

  def host; 'alert.victorops.com'; end

  def http_scheme; 'https://'; end

  def integrations_path_for_key(key); File.join(integrations_path, key).to_s ;end

  def integrations_path; "integrations/generic/20131114/alert"; end

  def stdout_logger(msg); "VICTOROPS SERVICE: " + msg; end

  def headers; { 'Content-Type' => 'application/json' }; end
end
