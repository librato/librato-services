require File.expand_path('../helper', __FILE__)

class OpsgenieTest < Librato::Services::TestCase
  def setup
    @settings = {customer_key: 'abc1234'}
  end

  def test_receive_validate
    service = service(:dummy, @settings, {})
    errors = {}
    result = service.receive_validate(errors)
    assert result, "Expected validation to return true"
    assert errors.empty?, "Expected no errors"
  end

  def test_receive_validate_strips_token
    settings = {customer_key: ' abc '}
    payload = {}
    service = service(:dummy, settings, payload)
    assert service.receive_validate
    assert settings[:customer_key] == 'abc', "Expected token whitespace to be stripped"
  end

  def service(*args)
    super Service::OpsGenie, *args
  end
end
