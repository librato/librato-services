# encoding: utf-8

class Service::Papertrail < Service

  def receive_validate(errors = {})
    success = true
    [:token].each do |k|
      value = settings[k]
      if value.to_s.empty?
        errors[k] = 'Is required'
        success = false
      end
    end

    return false unless success

    unless settings[:token].length > 10
      errors[:token] = "Token not valid"
      success = false
    end

    success
  end

  def receive_alert_clear
    raise_config_error unless receive_validate({})

  end

  def receive_alert
    raise_config_error unless receive_validate({})

  end

end
