require File.expand_path('../helper', __FILE__)

class MailTest < PapertrailServices::TestCase
  def setup

  end

  def test_logs
    svc = service(:logs, { :addresses => 'eric@sevenscale.com' }, payload)

    svc.mail_message.perform_deliveries = false

    svc.receive_logs
  end

  def test_mail_message
    svc = service(:logs, { :addresses => 'eric@sevenscale.com' }, payload)

    message = svc.mail_message

    assert_not_nil message
  end

  def test_html
    svc = service(:logs, { }, payload)

    html = svc.html_email

    assert_not_nil html
  end

  def test_text
    svc = service(:logs, { }, payload)

    text = svc.text_email

    assert_not_nil text
  end

  def service(*args)
    super Service::Mail, *args
  end
end