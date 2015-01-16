require File.expand_path('../helper', __FILE__)
require 'rspec/mocks/standalone'

class SNSTest < Librato::Services::TestCase
  include ::RSpec::Mocks::ExampleMethods

  def before_setup
    ::RSpec::Mocks.setup
    super
  end

  def test_validations
    svc = service(:alert, default_setting, alert_payload)
    errors = {}
    assert(svc.receive_validate(errors))
    assert(errors.empty?)

    # Missing settings
    svc = service(:alert, {}, alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(3, errors.length)
    errors.each_value { |err| assert(err.include?("Is required")) }

    # Invalid topic arn
    ['arn:aws:sns:us-east-1:ABC:test_topic',
     'arn:aws:sns:us-ea:st-1:123456789012:test_topic',
     'aws:sns:us-east-1:123456789012:test_topic',
     'arn:aws:sns:123456789012:test_topic',
     'arn:aws:sns:us-east-1:123456789012:test_!topic',
     'arn:aws:sns:us-east-1:123456789012:test_topic 12'
    ].each do |arn|
      svc = service(:alert, default_setting(topic_arn: arn), alert_payload)
      errors = {}

      assert(!svc.receive_validate(errors))
      assert_equal(1, errors.length)
      assert(errors[:topic_arn].include?('Should have format "arn:aws:sns:<region>:<account>:<topic_name>"'))
    end
  end

  def test_publish_message_errors
    aws_stub = Aws::SNS::Client.new(stub_responses: true, credentials: Aws::Credentials.new("key","secret"))
    expect(Aws::SNS::Client).to receive(:new).and_return aws_stub
    aws_stub.stub_responses(:publish,
                            Aws::SNS::Errors::SignatureDoesNotMatch,
                            Aws::SNS::Errors::AuthorizationError,
                            Aws::SNS::Errors::ServiceError.new(nil, 'Some horrible AWS Error'))

    svc = service(:alert, default_setting, alert_payload)

    assert_raise_with_message(Librato::Services::Service::ConfigurationError,
                              'Authentication failed - incorrect access key id or access key secret') do
      svc.publish_message({msg: ''})
    end

    assert_raise_with_message(Librato::Services::Service::ConfigurationError,
                              'Authorization failed - ensure that the user is allowed to perform SNS:Publish action') do
      svc.publish_message({msg: ''})
    end

    assert_raise_with_message(Librato::Services::Service::ServiceError, 'Some horrible AWS Error') do
      svc.publish_message({msg: ''})
    end
  end

  def test_receive_alarm
    aws_stub = double(Aws::SNS::Client)
    expect(Aws::SNS::Client).to receive(:new).and_return aws_stub
    expect(aws_stub).to receive(:publish).with(
      {
        topic_arn: 'arn:aws:sns:us-east-1:123456789012:test_topic-123',
        message: {
          alert: { id: 12345, name: '' },
          metric: { name: 'my_sample_alert', type: 'gauge' },
          measurement: { value: 2345.9, source: 'r3.acme.com' },
          measurements: [{ value: 2345.9, source: 'r3.acme.com'}],
          trigger_time: 1321311840
        }.to_json
      })

    svc = service(:alert, default_setting, alert_payload)
    svc.receive_alert
  end

  def test_receive_alert_multiple_measurements
    aws_stub = double(Aws::SNS::Client)
    expect(Aws::SNS::Client).to receive(:new).and_return aws_stub
    expect(aws_stub).to receive(:publish).with(
        {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:test_topic-123',
          message: {
            alert: { id: 12345 },
            metric: { name: 'my_sample_alert', type: 'gauge' },
            measurement: { value: 2345.9, source: 'r3.acme.com' },
            measurements: [{ value: 2345.9, source: 'r3.acme.com' },
                           { value: 123, source: 'r2.acme.com'}],
            trigger_time: 1321311840
          }.to_json
        })

    svc = service(:alert, default_setting, alert_payload_multiple_measurements)
    svc.receive_alert
  end

  def test_receive_clear
    aws_stub = double(Aws::SNS::Client)
    expect(Aws::SNS::Client).to receive(:new).and_return aws_stub
    expect(aws_stub).to receive(:publish).with(
      {
        topic_arn: 'arn:aws:sns:us-east-1:123456789012:test_topic-123',
        message: {
          alert: { id: 12345, name: '' },
          trigger_time: 1321311840,
          clear: 'normal'
        }.to_json
      })

    svc = service(:alert, default_setting, alert_payload)
    svc.receive_alert_clear
  end

  def test_receive_alert_v2
    aws_stub = double(Aws::SNS::Client)
    expect(Aws::SNS::Client).to receive(:new).and_return aws_stub
    expect(aws_stub).to receive(:publish).with(
      {
        topic_arn: 'arn:aws:sns:us-east-1:123456789012:test_topic-123',
        message: {
          alert: { id: 123, name: 'Some alert name', version: 2},
          trigger_time: 12321123,
          conditions: [{ type: 'above', threshold: 10, id: 1 }],
          violations: {
            "foo.bar" => [{ metric: 'metric.name', value: 100, recorded_at: 1389391083, condition_violated: 1 }]
          }
        }.to_json
      })

    svc = service(:alert, default_setting, new_alert_payload)
    svc.receive_alert
  end

  def assert_raise_with_message(klass, msg)
    begin
      yield
      assert(false, "Expected exception #{klass} was not raised")
    rescue klass => e
      assert(e.message.include?(msg), "Exception message \"#{e.message}\" did not include expected message \"#{msg}\"")
    end
  end

  def service(*args)
    super Service::SNS, *args
  end

  def default_setting(overrides = {})
    {
      topic_arn: "arn:aws:sns:us-east-1:123456789012:test_topic-123",
      access_key_id: "AKIAIRRA7Z6Z7DDEAVBA",
      secret_access_key: "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"
    }.merge(overrides)
  end

  def after_teardown
    super
    ::RSpec::Mocks.verify
  ensure
    ::RSpec::Mocks.teardown
  end
end
