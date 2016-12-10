require File.expand_path('../helper', __FILE__)
require 'rspec/mocks/standalone'

class LambdaTest < Librato::Services::TestCase
  include ::RSpec::Mocks::ExampleMethods

  def before_setup
    ::RSpec::Mocks.setup
    super
  end

  def test_validations
    svc = service(:alert, default_setting, new_alert_payload)
    errors = {}
    assert(svc.receive_validate(errors))
    assert(errors.empty?)

    # Missing
    svc = service(:alert, {}, new_alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    errors.each_value { |err| assert(err.include?("Is required")) }

    # Invalid function ARNs
    [
     "arn:aws:sns:us-west-2:1234567890:function:my-simple-function",
     "arn:aws:lambda:us-west-2:1234567890:my-simple-function",
     "arn:aws:lambda:us-west-2:1234567890:function:",
     "arn:aws:lambda:1234567890:function:my-simple-function",
     "my-simple-function"
    ].each do |arn|
      svc = service(:alert, default_setting(function_arn: arn), new_alert_payload)
      errors = {}

      assert(!svc.receive_validate(errors))
      assert_equal(1, errors.length)
      assert(errors[:function_arn].include?('Should have format "arn:aws:lambda'))
    end

    # Valid function ARNs
    [
     "arn:aws:lambda:us-west-2:1234567890:function:my-simple-func",
     "arn:aws:lambda:us-west-2:1234567890:function:my-simple-func:some-alias",
     "arn:aws:lambda:us-west-2:1234567890:function:my-simple-func:1.0",
    ].each do |arn|
      svc = service(:alert, default_setting(function_arn: arn), new_alert_payload)
      errors = {}

      assert(svc.receive_validate(errors))
      assert(errors.empty?)
    end
  end

  def test_deliver_msg
    aws_stub = Aws::Lambda::Client.new(stub_responses: true, credentials: Aws::Credentials.new("key","secret"))
    expect(Aws::Lambda::Client).to receive(:new).and_return aws_stub
    aws_stub.stub_responses(:invoke,
                            Aws::Lambda::Errors::ResourceNotFoundException.new(nil, ''),
                            Aws::Lambda::Errors::AccessDeniedException.new(nil, ''),
                            Aws::Lambda::Errors::ServiceError.new(nil, 'Some horrible AWS Error'))

    svc = service(:alert, default_setting, new_alert_payload)

    assert_raise_with_message(Librato::Services::Service::ConfigurationError,
                              'Lambda function does not exist') do
      svc.receive_alert()
    end

    assert_raise_with_message(Librato::Services::Service::ConfigurationError,
                              'Authorization failed') do
      svc.receive_alert()
    end

    assert_raise_with_message(Librato::Services::Service::ServiceError, 'Some horrible AWS Error') do
      svc.receive_alert()
    end
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
    super Service::Lambda, *args
  end

  def default_setting(overrides = {})
    {
      function_arn: "arn:aws:lambda:us-west-2:1234567890:function:my-simple-func"
    }.merge(overrides)
  end

  def after_teardown
    super
    ::RSpec::Mocks.verify
  ensure
    ::RSpec::Mocks.teardown
  end
end
