class Service::Zapier < Service
  def receive_validate(errors = {})
    if settings[:url].to_s.empty?
      errors[:url] = "Is required"
      return false
    end

    begin
      URI.parse(settings[:url])
    rescue URI::Error => err
      errors[:url] = "Is not valid"
      return false
    end

    return true
  end

  def receive_alert
    raise_config_error unless receive_validate({})
    raise_config_error('Zapier does not support V1 alerts') unless payload[:alert][:version] == 2
    send_alert(body)
  end

  def send_alert(outgoing_payload)
    url = settings[:url]
    begin
      http_post(url, outgoing_payload, headers)
    rescue Faraday::Error::ConnectionFailed
      log("Connection failed for url: #{url} for payload: #{payload.inspect}")
    end
  end

  def body
    outgoing_payload = {
      :id => payload[:alert][:id],
      :name => payload[:alert][:name],
      :description => "",
      :runbook_url => "",
      :violations => []
    }

    outgoing_payload.tap do
      outgoing_payload[:description] = payload[:alert][:description] if present?(payload[:alert][:description])
      outgoing_payload[:runbook_url] = payload[:alert][:runbook_url] if present?(payload[:alert][:runbook_url])

      if payload[:violations]
        output = Librato::Services::Output.new(payload)
        outgoing_payload[:violations] = payload[:violations].flat_map do |source, measurements|
          measurements.map { |measurement| output.format_measurement(measurement, source) }
        end
      end
    end
  end

  def headers
    { 'Content-Type'  => 'application/json' }
  end

  def present?(str)
    str && !str.empty?
  end

  def log(msg)
    Rails.logger.info(msg) if defined?(Rails)
  end
end
