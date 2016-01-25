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
      :clear => payload.fetch('clear', 'normal')
    }

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
    sns.publish(topic_arn: topic_arn, message: json_message_generator_for(msg), message_structure: 'json')
  rescue Aws::SNS::Errors::SignatureDoesNotMatch
    raise_config_error 'Authentication failed - incorrect access key id or access key secret'
  rescue Aws::SNS::Errors::AuthorizationError
    raise_config_error 'Authorization failed - ensure that the user is allowed to perform SNS:Publish action '\
                       'on the topic and that the topic arn is correct'
  rescue Aws::SNS::Errors::ServiceError => e
    raise_error e.message
  end

  def json_message_generator_for(msg)
    json = {
      :default => msg.to_json
    }

    if payload[:clear]
      trigger_time_utc = DateTime.strptime(payload[:trigger_time].to_s, "%s").strftime("%a, %b %e %Y at %H:%M:%S UTC")
      json[:sms] = "Alert '#{payload[:alert][:name]}' has cleared at #{trigger_time_utc}"
    elsif payload[:alert][:version] == 2
      json[:sms] = Librato::Services::Output.new(payload).sms_message
    end

    json.to_json
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
