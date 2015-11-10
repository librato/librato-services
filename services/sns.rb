# encoding: utf-8

require 'aws-sdk-core'

class Service::SNS < Service

  def receive_validate(errors = {})
    success = true
    [:topic_arn, :access_key_id, :secret_access_key].each do |k|
      value = settings[k]
      if value.to_s.empty?
        errors[k] = 'Is required'
        success = false
      end
    end

    return false unless success

    unless settings[:topic_arn] =~ /\Aarn:aws:sns:[^:]+:[0-9]+:[a-zA-Z0-9\-_]+\Z/
      errors[:topic_arn] =
        'Should have format "arn:aws:sns:<region>:<account>:<topic_name>" with'\
        'only alphanumeric characters, hyphens and underscores in topic_name.'
      success = false
    end

    success
  end

  def receive_alert_clear
    raise_config_error unless receive_validate({})

    msg = {
      :alert => payload['alert'],
      :trigger_time => payload['trigger_time'],
      :clear => payload['clear'],
    }
    msg[:incident_key] = payload['incident_key'] if payload.key?('incident_key')
    publish_message(msg)
  end

  def receive_alert
    raise_config_error unless receive_validate({})

    if payload[:alert][:version] == 2
      msg = {
        :alert => payload['alert'],
        :trigger_time => payload['trigger_time'],
        :conditions => payload['conditions'],
        :violations => payload['violations'],
        :triggered_by_user_test => payload['triggered_by_user_test']
      }
      msg[:incident_key] = payload['incident_key'] if payload.key?('incident_key')
    else
      measurements = get_measurements(payload)[0..19]
      msg = {
        :alert => payload['alert'],
        :metric => payload['metric'],
        :measurement => measurements[0],
        :measurements => measurements,
        :trigger_time => payload['trigger_time']
      }
    end

    publish_message(msg)
  end

  def publish_message(msg)
    sns.publish(topic_arn: topic_arn, message: msg.to_json)
  rescue Aws::SNS::Errors::SignatureDoesNotMatch
    raise_config_error 'Authentication failed - incorrect access key id or access key secret'
  rescue Aws::SNS::Errors::AuthorizationError
    raise_config_error 'Authorization failed - ensure that the user is allowed to perform SNS:Publish action '\
                       'on the topic and that the topic arn is correct'
  rescue Aws::SNS::Errors::ServiceError => e
    raise_error e.message
  end

  def region
    @region ||=
      topic_arn =~ /arn:aws:sns:([^:]+):/ ? $1 : raise_config_error('Invalid topic ARN (could not find region)')
  end

  def topic_arn
    @topic_arn ||= settings[:topic_arn]
  end

  def sns
    @sns ||=
      Aws::SNS::Client.new(
        credentials: Aws::Credentials.new(settings[:access_key_id], settings[:secret_access_key]),
        region: region)
  end

end
