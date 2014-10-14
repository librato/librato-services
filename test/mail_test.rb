require File.expand_path('../helper', __FILE__)

class MailTest < Librato::Services::TestCase
  def setup

  end

  def test_validations
    svc = service(:alert, { :addresses => 'fred@barn.com' }, alert_payload)
    errors = {}
    assert(svc.receive_validate(errors))
    assert_equal(0, errors.length)

    svc = service(:alert, { :addresses => 'fred@barn.com,collin@barn.com' }, alert_payload)
    errors = {}
    assert(svc.receive_validate(errors))
    assert_equal(0, errors.length)

    svc = service(:alert, { :addresses => 'fred@barn.com, collin@barn.com' }, alert_payload)
    errors = {}
    assert(svc.receive_validate(errors))
    assert_equal(0, errors.length)

    svc = service(:alert, { :addresses => 'fred@barn.com collin@barn.com' }, alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    assert(errors[:addresses])

    svc = service(:alert, {}, alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    assert(errors[:addresses])

    svc = service(:alert, { :addresses => ['fred@barn.com'] }, alert_payload)
    errors = {}
    assert(!svc.receive_validate(errors))
    assert_equal(1, errors.length)
    assert(errors[:addresses])
  end

  def test_new_alerts
    svc = service(:alert, { :addresses => 'fred@barn.com' }, new_alert_payload)
    svc.mail_message.perform_deliveries = false
    svc.receive_alert
  end

  def test_alert_multiple_measurements
    svc = service(:alert, { :addresses => 'fred@barn.com' }, alert_payload_multiple_measurements)
    svc.mail_message.perform_deliveries = false
    svc.receive_alert
  end

  def test_alert
    svc = service(:alert, { :addresses => 'fred@barn.com' }, alert_payload)
    svc.mail_message.perform_deliveries = false
    svc.receive_alert
  end

  def test_mail_message_alert
    svc = service(:alert, { :addresses => 'fred@barn.com' }, alert_payload)
    message = svc.mail_message
    assert_equal "[Librato] Alert  has triggered!", message.subject
    assert_not_nil message
    assert(!message.to.empty?)
  end

  def test_mail_message_new_alert
    svc = service(:alert, { :addresses => 'fred@barn.com' }, new_alert_payload)
    message = svc.mail_message
    assert_equal "[Librato] Alert Some alert name has triggered!", message.subject
    assert_not_nil message
    assert(!message.to.empty?)
  end

  def test_mail_message_new_alert_clear_normal
    payload = new_alert_payload.dup
    payload[:clear] = "normal"
    svc = service(:alert, { :addresses => 'fred@barn.com' }, payload)
    message = svc.mail_message
    assert_equal "[Librato] Alert Some alert name has cleared at 1970-05-23 14:32:03 UTC.", message.subject
    assert_not_nil message
    assert(!message.to.empty?)
  end

  def test_mail_message_new_alert_clear_unsupported
    payload = new_alert_payload.dup
    payload[:clear] = "unknown"
    svc = service(:alert, { :addresses => 'fred@barn.com' }, payload)
    message = svc.mail_message
    assert_equal "[Librato] Alert Some alert name has cleared at 1970-05-23 14:32:03 UTC.", message.subject
    assert_not_nil message
    assert(!message.to.empty?)
  end

  def test_mail_message_new_alert_clear_manual
    payload = new_alert_payload.dup
    payload[:clear] = "manual"
    svc = service(:alert, { :addresses => 'fred@barn.com' }, payload)
    message = svc.mail_message
    assert_equal "[Librato] Alert Some alert name was manually cleared at 1970-05-23 14:32:03 UTC.", message.subject
    assert_not_nil message
    assert(!message.to.empty?)
  end

  def test_mail_message_new_alert_clear_auto
    payload = new_alert_payload.dup
    payload[:clear] = "auto"
    svc = service(:alert, { :addresses => 'fred@barn.com' }, payload)
    message = svc.mail_message
    assert_equal "[Librato] Alert Some alert name was automatically cleared at 1970-05-23 14:32:03 UTC.", message.subject
    assert_not_nil message
    assert(!message.to.empty?)
  end

  def test_blacklist
    save_bl = ENV['BLACKLISTED_EMAILS']

    ENV['BLACKLISTED_EMAILS'] = 'fred@barn.com'
    svc = service(:alert, { :addresses => 'fred@barn.com' }, alert_payload)

    message = svc.mail_message
    ENV['BLACKLISTED_EMAILS'] = save_bl

    assert(message.to.empty?)
  end

  def test_html
    svc = service(:alert, { }, alert_payload)

    html = svc.html_email

    assert_not_nil html
  end

  def test_text
    svc = service(:alert, { }, alert_payload)

    text = svc.text_email

    assert_not_nil text
  end

  def service(*args)
    super Service::Mail, *args
  end
end
