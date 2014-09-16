require 'uri'
require 'debugger'

class Service::VictorOps < Service

  MOCK = true
  REQUIRED_SETTING_KEYS = [:api_key]

  def receive_validate(errors = {})
    REQUIRED_SETTING_KEYS.inject(true) do |previous_passed, key|
      key_not_found = settings[key].to_s.empty?
      if key_not_found
        errors[:name] = "Is required"
        return false
      end
      previous_passed && key_not_found
    end
  end

  def receive_alert
    stdout_logger "Payload: #{payload}"
    stdout_logger "Settings: #{settings}"

    body = {
      api_key: settings[:api_key],
      event_type: settings[:event_type],
      description: settings[:description],
      monitoring_tool: 'librato'
    }.merge(flatten_hash payload)
    body[:entity_id] = settings[:incident_key] if settings[:incident_key]

    uri = uri_for_key body[:api_key]
    debugger
    http_post uri, body, headers
  end

  private

  def state_message
    payload['payload']['alert']['name']
  end

  def flatten_hash(payload)
    {
      alert_name: payload['alert']['name'],
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

  def uri_for_key(key); URI.join("#{http_scheme}#{host}", integrations_path_for_key(key) ); end

  def host; 'alert.victorops.com'; end

  def http_scheme; 'https://'; end

  def integrations_path_for_key(key); URI.join(integrations_path, key) ;end

  def integrations_path; "https://alert.victorops.com/integrations/generic/20131114/alert"; end

  def stdout_logger(msg)
    return unless MOCK
    "VICTOROPS SERVICE: " + msg
  end

  def headers
    {
      'Content-Type' => 'application/json'
    }
  end
end
