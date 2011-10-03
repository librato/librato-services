# encoding: utf-8
require 'erb'

class Service::Mail < Service
  def receive_validate(errors)
    if settings[:addresses].to_s.empty?
      errors[:addresses] = "Is required"
      false
    else
      true
    end
  end

  def receive_alert
    raise_config_error unless receive_validate({})

    mail_message.deliver
  end

  def mail_message
    @mail_message ||= begin
      mail = ::Mail.new
      mail.from    'Librato Metrics <metrics@librato.com>'
      mail.to      settings[:addresses].split(/,/).map { |a| a.strip }
      mail.subject %{[Librato Metrics] Alert #{payload[:alert][:id]} fired!}

      text = text_email
      html = html_email

      mail.text_part do
        body text
      end

      mail.html_part do
        content_type 'text/html; charset=UTF-8'
        body html
      end

      mail.delivery_method :smtp, smtp_settings

      mail
    end
  end

  def html_email
    erb(unindent(<<-EOF), binding)

<htm>
  <head>
    <title>Librato Metrics</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  </head>
  <body style="background-color: #2a2a2a; padding: 0px; margin: 0px;">
    <table width="100%" cellpadding="20" cellspacing="0">
      <tr>
        <td align="center" valign="top">
          <table width="600" cellpadding="0" cellspacing="0" class="container" style="border: 1px solid #000000;">
            <tr>
              <td align="center" valign="top">
                <div id="headbar" style="background-color: #000000;padding: 20px;border-bottom: 0px solid #000000;">
                  <div id="headlogo" style="color: #CCC; font-size: 3em; font-family: Arial; font-weight: bold; text-align: left; text-shadow: black 0px 2px 0px, #E5E5E5 0px -1px 0px; vertical-align: middle">
                    <img src="https://s3.amazonaws.com/librato_images/logo_auth.png" alt="Librato Metrics">
                  </div>
                </div>
              </td>
            </tr>
            <tr>
              <td valign="top" align="left" style="background-color: #FFFFFF;padding: 20px;font-family: Arial;font-size: 12px;line-height: 150%;color: #333333;">
                <div id="content">
                  <h2>Alert <%= h payload[:alert][:id] %> has fired</h2>
                  Payload: <%= h payload.inspect %>
                </div>
              </td>
            </tr>
            <tr>
              <td valign="top" align="center" style="background-color: #FFFFFF;padding: 20px;font-family: Arial;font-size: 10px;line-height: 150%;color: #333333;">
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
EOF
  end

  def text_email
    erb(unindent(<<-EOF), binding)
      Alert <%= h payload[:alert][:id] %> has fired.

      Payload: <%= payload.inspect %>

      --
      Librato Metrics
      metrics@librato.com - https://metrics.librato.com/
    EOF
  end
end
