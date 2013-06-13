# encoding: utf-8

require 'services/mail'

class Service::Flowdock < Service::Mail
  attr_writer :flowdock

  def receive_validate(errors = {})
    success = true
    [:api_token, :user_name].each do |k|
      if settings[k].to_s.empty?
        errors[k] = "Is required"
        success = false
      end
    end
    success
  end

  def receive_snapshot
    raise_config_error unless receive_validate({})

    flowdock.push_to_chat(:content => "%s: %s" % [
      payload[:snapshot][:entity_name],
      payload[:snapshot][:entity_url]])
    flowdock.push_to_chat(:content => payload[:snapshot][:image_url])
  end

  def receive_alert
    raise_config_error unless receive_validate({})

    flowdock.push_to_team_inbox(
      :subject => mail_message.subject,
      :content => mail_message.html_part.body,
      :link => metric_link(payload[:metric][:type], payload[:metric][:name]))
  end

  def flowdock
    @flowdock ||= Flowdock::Flow.new(
      :api_token => settings[:api_token],
      :external_user_name => settings[:user_name],
      :source => "Librato Metrics",
      :from => {
        :name => "Librato Metrics",
        :address => "metrics@librato.com"})
  rescue Flowdock::Flow::ApiError => ai
    if ai.message =~ /Invalid tokens/
      raise_error 'Authentication failed — invalid token'
    else
      raise_error ai.message
    end
  end
end
