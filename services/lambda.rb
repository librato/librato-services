# encoding: utf-8

require 'aws-sdk-core'

class Service::Lambda < Service

  def receive_validate(errors = {})
    success = true
    [:function_arn].each do |k|
      value = settings[k]
      if value.to_s.empty?
        errors[k] = 'Is required'
        success = false
      end
    end

    return false unless success

    unless settings[:function_arn] =~ /\Aarn:aws:lambda:[^:]+:[0-9]+:function:[a-zA-Z0-9\-_\.:]+\Z/
      errors[:function_arn] =
        'Should have format "arn:aws:lambda:<region>:<account>:function:<function_name>" with'\
        'only alphanumeric characters, hyphens and underscores in function name.'
       success = false
    end

    success
  end

  def receive_alert_clear
    receive_notification('alert_clear')
  end

  def receive_alert
    receive_notification('alert_trigger')
  end

  def receive_snapshot
    receive_notification('snapshot')
  end

  private

  def receive_notification(type)
    raise_config_error unless receive_validate({})

    msg = build_payload(type, payload)
    publish_message(msg)
  end

  private

  def build_payload(event_type, payload)
    p = {'event_type' => event_type}

    if payload['alert']
      p['alert'] = payload['alert']

      if payload['alert']['version'] == 2
        p['trigger_time'] = payload['trigger_time']
        p['conditions'] = payload['conditions']
        p['violations'] = payload['violations']

        if payload['triggered_by_user_test']
          p['triggered_by_user_test'] = payload['triggered_by_user_test']
        end

        if payload['incident_key']
          p['incident_key'] = payload['incident_key']
        end
      end
    end

    if payload['snapshot']
      p['snapshot'] = payload['snapshot']
    end

    p
  end

  def publish_message(msg)
    resp = lambda.invoke({function_name: function_arn, invocation_type: 'Event', log_type: 'None', payload: msg.to_json})
    if resp.status_code / 100 != 2
      raise_error "Failed to invoke #{function_arn}: #{resp.status_code}/#{resp.function_error}"
    end
  rescue Aws::Lambda::Errors::ResourceNotFoundException
    raise_config_error "Lambda function does not exist: #{function_arn}"
  rescue Aws::Lambda::Errors::AccessDeniedException
    raise_config_error 'Authorization failed - ensure that Librato is allowed to invoke the lambda function'
  rescue Aws::Lambda::Errors::ServiceError => e
    raise_error e.message
  end

  def region
    @region ||=
      function_arn =~ /arn:aws:lambda:([^:]+):/ ? $1 : raise_config_error('Invalid function ARN (could not find region)')
  end

  def function_arn
    @function_arn ||= settings[:function_arn]
  end

  def lambda
    @lambda ||=
      Aws::Lambda::Client.new(
        credentials: Aws::Credentials.new(ENV['LAMBDA_INVOCATION_ACCESS_ID'], ENV['LAMBDA_INVOCATION_ACCESS_KEY']),
        region: region)
  end

end
