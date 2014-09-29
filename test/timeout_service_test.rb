class TimeoutServiceTest < Librato::Services::TestCase

  class TimeoutService < Service
    def receive_alert_clear
    end
    def sample_payload
      {}
    end
    def receive_timeout_request
      sleep 30
    end
  end

  def test_verify_timeout_error
    event = :timeout_request
    settings = {}
    payload = { }
    failed = false
    begin
      TimeoutService.receive(event, settings, payload)
    rescue Timeout::Error => e
      # ok
      failed = true
    end
    assert failed
  end
end
