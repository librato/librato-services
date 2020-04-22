# encoding: utf-8
require 'time'

module Librato::Services
  class Service::PagerdutyV2 < Librato::Services::Service

    EVENTS_API_URL = "https://events.pagerduty.com/v2/enqueue"
    CONTENT_TYPE = { 'Content-Type': 'application/json' }

    ERROR_MSG = {
      routing_key: "The 32 character Integration Key (required).",
      description: "A description for this integration (require),",
      severity: "Perceived status of event [critical, error, warning or info] (required.)"
    }

    def receive_validate(errors)
      success = true
      [:routing_key, :description, :severity].each do |k|
        if settings[k].to_s.empty?
          errors[k] = ERROR_MSG[k]
          success = false
        end
      end
      success
    end

    def receive_alert_clear
      receive_alert
    end

    def receive_alert
      raise_config_error unless receive_validate({})

      if payload[:alert][:version] == 2
        http_post EVENTS_API_URL, body, CONTENT_TYPE
      else
        log("Only v2 Alerts are support")
        return true
      end
    end

    def body
      payload = {
        summary: summary,
        source: source,
        severity: severity,
        timestamp: timestamp,
        class: event_class,
        custom_details: details,
      }

      payload[:group] = group unless group.blank?

      {
        routing_key: routing_key,
        event_action: event_action,
        dedup_key: dedup_key,
        payload: payload,
        links: links,
      }
    end

    def routing_key
      settings[:routing_key]
    end

    def event_action
      payload[:clear] ? "resolve" : "trigger"
    end

    def dedup_key
      keys = [settings[:incident_key], payload[:incident_key]].compact
      keys.join("-")
    end

    def alert_name
      payload[:alert][:name]
    end

    def summary
      summary = alert_name.blank? ? settings[:description] : alert_name
      if payload[:triggered_by_user_test]
        description = "[Test] " + description
      end
      summary
    end

    def source
      sources = []
      payload[:violations].each do |source, _|
        sources << source
      end
      sources.join(":")
    end

    def event_class
      classes = []
      payload[:violations].each do |_, measurements|
        measurements.each do |m|
          classes << m[:metric]
        end
      end
      classes.join(":")
    end

    def severity
      settings[:severity]
    end

    def timestamp
      Time.at(payload['trigger_time']).iso8601
    end

    def group
      settings[:group]
    end

    def details
      details = {
      }

      [:alert, :conditions, :violations].each do |whitelisted|
        details[whitelisted] = payload[whitelisted]
      end

      if payload[:triggered_by_user_test]
        details[:note] = test_alert_message()
      end

      unless payload['alert']['description'].blank?
        details[:description] = payload['alert']['description']
      end

      details
    end

    def links
      links = [
        {
          href: alert_link(payload['alert']['id']),
          text: "Alert URL",
        },
      ]

      unless payload['alert']['runbook_url'].blank?
        links << {
          href: payload['alert']['runbook_url'],
          text: "Runbook URL",
        }
      end

      if payload[:alert][:version] == 1
        links << {
          href: payload_link(payload),
          text: "Metric URL",
        }
      end

      links
    end

    def log(msg)
      if defined?(Rails)
        Rails.logger.info(msg)
      else
        puts(msg)
      end
    end
  end
end
