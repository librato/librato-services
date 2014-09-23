require File.expand_path('../helper', __FILE__)

class PagerdutyTest < Librato::Services::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_validations
    params = {:service_key => 'k', :event_type => 't', :description => 'd'}

    0.upto(params.keys.length - 1) do |i|
      opts = {}
      0.upto(i) do |j|
        opts[params.keys[j]] = params[params.keys[j]]
      end
      svc = service(:alert, opts, alert_payload)
      errors = {}
      ret = svc.receive_validate(errors)
      success = i == params.keys.length - 1
      assert_equal(success, ret, "opts not complete: #{opts}")
      assert_equal(0, errors.length) if success
    end
  end

  def test_alerts_multiple_measurements
    svc = service(:alert, {
                    :service_key => 'k',
                    :event_type => 't',
                    :description => 'd'
                  }, alert_payload_multiple_measurements)

    @stubs.post '/generic/2010-04-15/create_event.json' do |env|
      [200, {}, '']
    end

    svc.receive_alert
  end

  def test_alerts
    svc = service(:alert, {
                    :service_key => 'k',
                    :event_type => 't',
                    :description => 'settings description'
                  }, alert_payload)

    @stubs.post '/generic/2010-04-15/create_event.json' do |env|
      [200, {}, '']
      # if the alert does not have a name, then verify it uses the description
      assert_equal 'settings description', env[:body][:description]
    end

    svc.receive_alert
  end

  def test_new_alerts
    svc = service(:alert, {
                    :service_key => 'k',
                    :event_type => 't',
                    :description => 'd'
                  }, new_alert_payload)

    @stubs.post '/generic/2010-04-15/create_event.json' do |env|
      assert_nil env[:body][:details]["auth"]
      assert_nil env[:body][:details]["settings"]
      assert_nil env[:body][:details]["service_type"]
      assert_nil env[:body][:details]["event_type"]
      assert_not_nil env[:body][:details]["violations"]
      assert_not_nil env[:body][:details]["conditions"]
      assert_not_nil env[:body][:details]["trigger_time"]
      assert_not_nil env[:body][:details]["alert"]
      assert_not_nil env[:body][:details]["user_id"]
      assert_equal "trigger", env[:body][:event_type]
      assert_equal "foo", env[:body][:incident_key]
      assert_equal 'Some alert name', env[:body][:description]
      [200, {}, '']
    end

    svc.receive_alert
  end

  def test_new_alerts_clearing
    payload = new_alert_payload.dup
    payload[:clear] = true
    svc = service(:alert, {
                    :service_key => 'k',
                    :event_type => 't',
                    :description => 'd'
                  }, payload)

    @stubs.post '/generic/2010-04-15/create_event.json' do |env|
      assert_nil env[:body][:details]["auth"]
      assert_nil env[:body][:details]["settings"]
      assert_nil env[:body][:details]["service_type"]
      assert_nil env[:body][:details]["event_type"]
      assert_not_nil env[:body][:details]["violations"]
      assert_not_nil env[:body][:details]["conditions"]
      assert_not_nil env[:body][:details]["trigger_time"]
      assert_not_nil env[:body][:details]["alert"]
      assert_not_nil env[:body][:details]["user_id"]
      assert_equal "resolve", env[:body][:event_type]
      assert_equal "foo", env[:body][:incident_key]
      assert_equal 'Some alert name', env[:body][:description]
      [200, {}, '']
    end

    svc.receive_alert
  end

  def service(*args)
    super Service::Pagerduty, *args
  end
end
