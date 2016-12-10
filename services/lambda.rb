# encoding: utf-8

#
# AWS Lambda Librato service
# --------------------------
#
# Deliver Librato alert triggers/clears and snapshots to an AWS Lambda
# function.
#
# Configuration
# =============
#
#   function_arn: (required) ARN of function name
#        Example: arn:aws:lambda:us-west-2:1234567890:function:my-simple-func
#
# The function must be given `lambda:InvokeFunction` permission from the
# Librato AWS Account ID. For example, to add permission to a function
# name of "my-simple-func" in the "us-west-2" region using the AWS
# CLI:
#
#  $ aws lambda add-permission --function-name my-simple-func \
#                         --region us-west-2 \
#                         --action "lambda:InvokeFunction" \
#                         --principal <Librato AWS Account ID> \
#                         --statement-id Id-123
#
# The following environment variables must be set to the callee
# account's AWS credentials:
#
#  LAMBDA_INVOCATION_ACCESS_ID
#  LAMBDA_INVOCATION_ACCESS_KEY
#
# Description
# ===========
#
# This service will invoke the function asynchronously (invocation
# type: 'Event) and pass the alert or snapshot JSON payload.
#
# The payload will contain the key 'event_type' set to the value of
# either: 'alert_trigger', 'alert_clear', or 'snapshot' and can be
# used to identify the type of event.
#
# A triggered alert payload looks like (only v2 alerts are supported):
#
#  {
#    "event_type":"alert_trigger",
#    "trigger_time":12321123,
#    "alert":{
#       "runbook_url":"http://runbooks.com/howtodoit",
#       "description":"Verbose alert explanation",
#       "version":2,
#       "id":123,
#       "name":"Some alert name"
#    },
#    "incident_key":"foo",
#    "violations":{
#       "foo.bar":[
#          {
#             "metric":"metric.name",
#             "condition_violated":1,
#             "value":100,
#             "recorded_at":1389391083
#          }
#       ]
#    },
#    "conditions":[
#       {
#          "threshold":10,
#          "type":"above",
#          "id":1
#       }
#    ]
# }
#
# A snapshot payload looks like:
#
# {
#    "event_type":"snapshot",
#    "snapshot":{
#       "entity_name":"App API Requests",
#       "entity_url":"https://metrics.librato.com/instruments/1234?duration=3600",
#       "image_url":"http://snapshots.librato.com/instruments/12345abcd.png",
#       "user":{
#          "email":"mike@librato.com",
#          "full_name":"Librato User"
#       },
#       "message":"Explanation of this snapshot",
#       "subject":"Subject of API Requests"
#    }
# }

#
######


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
