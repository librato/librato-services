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
    check = payload['alert']['name']
    if payload[:triggered_by_user_test]
      check = "[Test] " + check
    end
    body = {
      'app_key' => settings[:app_key],
      'primary_property' => 'check',
      'check' => check,
      'timestamp' => payload['trigger_time']
    }

    body['description'] = payload['alert']['description'] if payload['alert']['description']
    body['runbook_url'] = payload['alert']['runbook_url'] if present?(payload['alert']['runbook_url'])
    body['link'] = alert_link(payload['alert']['id'])

    if payload[:triggered_by_user_test]
      body['note'] = test_alert_message(payload['auth']['email'])
    end

    if payload['violations']
      sources = []
      violations = []
      index = 1
      output = Librato::Services::Output.new(payload)
      payload['violations'].each do |source, measurements|
        sources << source
        measurements.each do |measurement|
          violations << "Violation #{index}: #{output.format_measurement(measurement, source)}"
          index += 1
        end
      end
      body['violations'] = violations.join('. ')
      body['sources'] = sources.join(', ')
    end

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

  def present?(str)
    str && !str.empty?
  end
end
