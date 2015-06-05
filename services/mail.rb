# encoding: utf-8
require 'erb'
require 'mail'

class Service::Mail < Service
  def receive_validate(errors)
    addresses = settings[:addresses]
    if addresses.to_s.empty?
      errors[:addresses] = "Is required"
      return false
    end
    if addresses.class != String
      errors[:addresses] = "Must be a comma-separated string"
      return false
    end
    addresses = addresses.to_s.strip
    addresses.split(/,/).each do |address|
      if address.strip =~ /\s/
        errors[:addresses] = "Must be a comma-separated string"
        return false
      end
    end
    true
  end

  def receive_alert_clear
    receive_alert
  end

  def receive_alert
    raise_config_error unless receive_validate({})
    mm = mail_message
    mm.deliver unless mm.to.empty?
  end

  def mail_addresses
    @addresses ||=
      filter_addresses(settings[:addresses].to_s.split(/,/).map { |a| a.strip })
  end

  def mail_message
    @mail_message ||= begin
      mail = ::Mail.new
      mail.from    'Librato <metrics@librato.com>'
      mail.to      mail_addresses
      mail.header['X-Mailgun-Tag'] = 'alerts'
      trigger_time_utc = Time.at(payload[:trigger_time]).utc
      if payload[:clear]
        mail.subject %{[Librato] Alert #{payload[:alert][:name]} has cleared.}
      else
        mail.subject %{[Librato] Alert #{payload[:alert][:name]} has triggered!}
      end

      if payload[:alert][:version] == 2
        output = Librato::Services::Output.new(payload)
        text = output.markdown
        html = new_html_email(output.html)
      else
        text = text_email
        html = html_email
      end

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

  def filter_addresses(addresses)
    addresses.reject {|a| email_blacklist.include?(a.downcase) }
  end

  #TODO change when no longer "new"
  def new_html_email(html)
    <<-EOF
<html>
  <head>
    <title>Librato Alert</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  </head>
  <body>
    <!-- Begin backgroundTable -->
    <table id="backgroundTable" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse !important; background-color: #ffffff; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; height: 100% !important; margin: 0; padding: 0; width: 100% !important;" border="0" width="100% !important" cellspacing="0" cellpadding="0" align="center" bgcolor="#ffffff">
      <tbody>
        <tr>
          <td id="bodyCell" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; height: 100% !important; margin: 0; padding: 0; width: 100% !important;" align="center" valign="top" width="100% !important" height="100% !important">
            <!-- When nesting tables within a TD, align center keeps it well, centered. --> <!-- Begin Template Container --> <!-- This holds everything together in a nice container -->
            <table id="templateTable" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse !important; width: 600px; background-color: #ffffff; -webkit-font-smoothing: antialiased;" border="0" width="600" cellspacing="0" cellpadding="0" bgcolor="#ffffff">
              <tbody>
                <tr>
                  <td id="contentCell" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; padding: 10px 20px; background-color: #ffffff;" align="center" valign="top" bgcolor="#ffffff">
                    <!-- Begin Template Wrapper --> <!-- This separates the preheader which usually contains the "open in browser, etc" content
                      from the actual body of the email. Can alternatively contain the footer too, but I choose not
                      to so that it stays outside of the border. -->
                    <table id="contentTableOuter" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: separate !important; background-color: #ffffff; padding: 30px;" border="0" width="100%" cellspacing="0" cellpadding="0" bgcolor="#ffffff">
                      <tbody>
                        <tr>
                          <td style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt;" align="center" valign="top">
                            <div class="body-container-wrapper">&nbsp;</div>
                            <table id="contentTableInner" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse !important; width: 600px;" border="0" width="600" cellspacing="0" cellpadding="0">
                              <tbody>
                                <tr>
                                  <td class="bodyContent" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; color: #4c4c4c; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 13px; line-height: 150%; text-align: left;" colspan="12" align="left" valign="top" width="100%">
                                    <table class="templateColumnWrapper" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse !important;" border="0" width="100%" cellspacing="0" cellpadding="0">
                                      <tbody>
                                        <tr>
                                          <td class="librato-logo-social column" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100.0%; text-align: left; padding: 0; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 13px; line-height: 1.5em; color: #4c4c4c;" colspan="12" align="left" valign="top" width="100.0%">
                                            <table style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse !important;" border="0" width="100%" cellspacing="0" cellpadding="0">
                                              <tbody>
                                                <tr>
                                                  <td class="bodyContent" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; color: #4c4c4c; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 13px; line-height: 150%; text-align: left;" colspan="12" align="left" valign="top" width="100%">
                                                    <table class="templateColumnWrapper" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse !important;" border="0" width="100%" cellspacing="0" cellpadding="0">
                                                      <tbody>
                                                        <tr>
                                                          <td class=" column" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100.0%; text-align: left; padding: 0; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 13px; line-height: 1.5em; color: #4c4c4c;" colspan="12" align="left" valign="top" width="100.0%">
                                                            <div class="widget-span widget-type-raw_html librato-logo" data-widget-type="raw_html">
                                                              <div class="layout-widget-wrapper">
                                                                <div id="hs_cos_wrapper_module_13982908004952215" class="hs_cos_wrapper hs_cos_wrapper_widget hs_cos_wrapper_type_raw_html" style="color: inherit; font-size: inherit; line-height: inherit; margin: inherit; padding: inherit;" data-hs-cos-general-type="widget" data-hs-cos-type="raw_html">
                                                                  <table style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse !important; border-spacing: 0; width: 100%; margin: 0; padding: 0;" width="100%" bgcolor="#FFFFFF">
                                                                    <tbody>
                                                                      <tr style="margin: 0; padding: 0;">
                                                                        <td class="logo" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse; margin: 0; padding: 0px 0px 20px 0px;"><a style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; text-decoration: none; margin: 0; padding: 0;" title="librato.com" href="https://librato.com"> <img id="logo" style="vertical-align: bottom; -ms-interpolation-mode: bicubic; max-width: 80%; margin: 0; padding: 0;" src="http://info.librato.com/hs-fs/hubfs/nl-librato-swi-logo-180px.png?t=1433444671840&amp;width=180" alt="" width="180" /> </a></td>
                                                                      </tr>
                                                                    </tbody>
                                                                  </table>
                                                                </div>
                                                              </div>
                                                              <!--end layout-widget-wrapper -->
                                                            </div>
                                                            <!--end widget-span -->
                                                          </td>
                                                        </tr>
                                                      </tbody>
                                                    </table>
                                                  </td>
                                                </tr>
                                              </tbody>
                                            </table>
                                          </td>
                                        </tr>
                                      </tbody>
                                    </table>
                                  </td>
                                </tr>
                                <tr>
                                  <td class="bodyContent" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; color: #4c4c4c; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 13px; line-height: 150%; text-align: left;" colspan="12" align="left" valign="top" width="100%">
                                    <table class="templateColumnWrapper" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse !important;" border="0" width="100%" cellspacing="0" cellpadding="0">
                                      <tbody>
                                        <tr>
                                          <td class=" column" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100.0%; text-align: left; padding: 0; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 13px; line-height: 1.5em; color: #4c4c4c;" colspan="12" align="left" valign="top" width="100.0%">
                                            <table style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse !important;" border="0" width="100%" cellspacing="0" cellpadding="0">
                                              <tbody>
                                                <tr>
                                                  <td class="bodyContent" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; color: #4c4c4c; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 13px; line-height: 150%; text-align: left;" colspan="12" align="left" valign="top" width="100%">
                                                    <div id="content">#{html}</div>
                                                  </td>
                                                </tr>
                                              </tbody>
                                            </table>
                                          </td>
                                        </tr>
                                      </tbody>
                                    </table>
                                  </td>
                                </tr>
                                <!--end body wrapper -->
                              </tbody>
                            </table>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                    <!-- End Template Wrapper -->
                  </td>
                </tr>
                <tr>
                  <td style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt;" align="center" valign="top">
                    <!-- Begin Template Footer -->
                    <div class="footer-container-wrapper">&nbsp;</div>
                    <table id="footerTable" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse !important; background-color: #ffffff; color: #999999; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 12px; line-height: 120%; text-align: center; padding: 20px;" border="0" width="100%" cellspacing="0" cellpadding="0" align="center" bgcolor="#ffffff">
                      <tbody>
                        <tr>
                          <td class="bodyContent" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; color: #4c4c4c; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 13px; line-height: 150%; text-align: left;" colspan="12" align="left" valign="top" width="100%">
                            <table class="templateColumnWrapper" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse !important;" border="0" width="100%" cellspacing="0" cellpadding="0">
                              <tbody>
                                <tr>
                                  <td class=" column" style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100.0%; text-align: left; padding: 0; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 13px; line-height: 1.5em; color: #4c4c4c;" colspan="12" align="left" valign="top" width="100.0%">
                                    <div class="widget-span widget-type-email_can_spam " data-widget-type="email_can_spam">
                                      <div id="footer" style="line-height: 1em; text-align: center;"><span style="font-size: 10px;">You received this email because you set up alerts with&nbsp;the&nbsp;Librato app.</span></div>
                                    </div>
                                    <!--end widget-span -->
                                  </td>
                                </tr>
                              </tbody>
                            </table>
                          </td>
                        </tr>
                        <!--end footer wrapper -->
                        <tr>
                          <td style="-webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; mso-table-lspace: 0pt; mso-table-rspace: 0pt;">&nbsp;</td>
                        </tr>
                      </tbody>
                    </table>
                    <!-- End Template Footer -->
                  </td>
                </tr>
              </tbody>
            </table>
            <!-- End Template Container -->
          </td>
        </tr>
      </tbody>
    </table>
  </body>
</html>
EOF
  end

  def html_email
    erb(unindent(<<-EOF), binding)

<html>
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
                    <img src="https://s3.amazonaws.com/librato_images/librato_logo.png" alt="Librato Metrics">
                  </div>
                </div>
              </td>
            </tr>
            <tr>
              <td valign="top" align="left" style="background-color: #FFFFFF;padding: 20px;font-family: Arial;font-size: 12px;line-height: 150%;color: #333333;">
                <div id="content">
                  <h2>Metric <%= h payload[:metric][:name] %> has triggered an alert!</h2>
                  <ul>
                    <li>Metric: <em><%= h payload[:metric][:name] %></em></li>
                    <% get_measurements(payload)[0..19].each do |measurement| %>
                      <li>
                        <% if measurement[:source] != 'unassigned' %>
                          <%= h measurement[:source] %> :
                        <% end %>
                        <em><%= h measurement[:value] %></em>
                      </li>
                    <% end %>
                    <li>Triggered at: <em><%= Time.at(payload[:trigger_time]).utc %></em></li>
                  </ul>
                  <p>
                    Click <a href="<%= payload_link(payload) %>">this link</a> to view the metric.
                  </p>
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
      Metric <%= h payload[:metric][:name] %> has triggered an alert!

      <%- get_measurements(payload)[0..19].each do |measurement| %>
      <%= measurement[:source] != 'unassigned' ? "%s: " % [measurement[:source]] : "" %><%= h measurement[:value] %>
      <%- end %>

      Triggered at: <%= Time.at(payload[:trigger_time]).utc %>

      View the metric here: <%= payload_link(payload) %>

      --
      Librato Metrics
      metrics@librato.com - https://metrics.librato.com/
    EOF
  end
end
