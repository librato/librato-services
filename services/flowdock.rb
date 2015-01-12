# encoding: utf-8

require 'services/mail'
require 'flowdock'

class Service::Flowdock < Service::Mail
  attr_writer :flowdock

  def receive_validate(errors = {})
    if settings[:api_token].to_s.empty?
      errors[:api_token] = "Is required"
      return false
    end

    unless settings[:user_name].blank?
      # No whitespace, < 16 chars
      if settings[:user_name].length >= 16 ||
          settings[:user_name].include?(" ")
        errors[:user_name] = "Invalid format"
        return false
      end
    end

    true
  end

  def receive_snapshot
    raise_config_error unless receive_validate({})

    send_messages snapshot_message
  end

  def snapshot_message
    snapshot = payload[:snapshot]
    name = snapshot[:entity_name] ? "#{snapshot[:entity_name]}: " : ''
    [
      "#{name} #{snapshot[:entity_url]} by #{snapshot[:user_email]}",
      snapshot[:message],
      snapshot[:image_url]
    ].compact
  end

  def receive_alert
    raise_config_error unless receive_validate({})

    flowdock.push_to_team_inbox(
      :subject => mail_message.subject,
      :content => mail_message.html_part.body,
      :link => payload_link(payload))
  end

  def send_messages(messages)
    messages.each { |m| flowdock.push_to_chat(content: m) }
  end

  def flowdock
    username = "Librato"
    username = settings[:user_name] unless settings[:user_name].blank?

    @flowdock ||= ::Flowdock::Flow.new(
      :api_token => settings[:api_token],
      :external_user_name => username,
      :source => "Librato Metrics",
      :from => {
        :name => "Librato Metrics",
        :address => "metrics@librato.com"})
  rescue ::Flowdock::Flow::ApiError => ai
    if ai.message =~ /Invalid tokens/
      raise_error 'Authentication failed — invalid token'
    else
      raise_error ai.message
    end
  end
end
