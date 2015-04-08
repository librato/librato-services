# See https://www.bigpanda.io/docs/integrations/index.html#alerts-rest-api
class Service::BigPanda < Service
  def receive_validate(errors = {})
    success = true
    [:app_key, :token].each do |k|
      if settings[k].to_s.empty?
        errors[k] = 'Is required'
        success = false
      end
    end
    success
  end

  def receive_alert
    raise_config_error unless receive_validate({})
    send_alert(body.merge('status' => 'critical'))
  end

  def receive_alert_clear
    raise_config_error unless receive_validate({})
    send_alert(body.merge('status' => 'ok'))
  end

  def send_alert(body)
    url = 'https://api.bigpanda.io/data/v2/alerts'
    begin
      http_post(url, body, headers)
    rescue Faraday::Error::ConnectionFailed
      log("Connection failed for url: #{url} for payload: #{payload.inspect}")
    end
  end

  def body
    body = {
      'app_key' => settings[:app_key],
      'service' => 'Librato',
      'check' => payload['alert']['name'],
      'timestamp' => payload['trigger_time']
    }

    body['description'] = payload['alert']['description'] if payload['alert']['description']
    body['runbook_url'] = payload['alert']['runbook_url'] if payload['alert']['runbook_url']

    output = Librato::Services::Output.new(payload)
    violations = []
    payload['violations'].each do |key, metric|
      metric.each {|v| violations << output.format_measurement(v) }
    end
    body['violations'] = violations.join('\n')
    body
  end

  def headers
    {'Authorization' => "Bearer #{settings[:token]}",
     'Content-Type'  => 'application/json'}
  end

  def log(msg)
    if defined?(Rails)
      Rails.logger.info(msg)
    else
      puts(msg)
    end
  end
end
