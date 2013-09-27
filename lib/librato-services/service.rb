

Dir[File.join(File.dirname(__FILE__), 'helpers/*helpers*')].each { |helper|
  require helper
}

require 'helpers/alert_helpers'

module Librato
  module Services
    class Service
      TIMEOUT = 20

      def self.receive(event, settings, payload, *args)
        svc = new(event, settings, payload)

        event_method = "receive_#{event}".to_sym
        if svc.respond_to?(event_method)
          # XXX: Need a timeout!
          #Timeout.timeout(TIMEOUT, TimeoutError) do
          svc.send(event_method, *args)
          #end

          true
        else
          false
        end
      end

      def self.services
        @services ||= {}
      end

      def self.hook_name
        @hook_name ||= begin
                         hook = name.dup
                         hook.downcase!
                         hook.sub! /.*:/, ''
                         hook
                       end
      end

      def self.inherited(svc)
        Librato::Services::Service.services[svc.hook_name] = svc
        Librato::Services::App.service(svc)
        super
      end

      attr_reader :event
      attr_reader :settings
      attr_reader :payload
      attr_writer :http

      def initialize(event = :alert, settings = {}, payload = nil)
        helper_name = "#{event.to_s.capitalize}Helpers"
        if Librato::Services::Helpers.const_defined?(helper_name)
          @helper = Librato::Services::Helpers.const_get(helper_name)
          extend @helper
        end

        @event    = event
        @settings = settings
        @payload  = payload || sample_payload
      end

      def http_get(url = nil, params = nil, headers = nil)
        http.get do |req|
          req.url(url)                if url
          req.params.update(params)   if params
          req.headers.update(headers) if headers
          yield req if block_given?
        end
      end

      def http_post(url = nil, body = nil, headers = nil)
        http.post do |req|
          req.url(url)                if url
          req.headers.update(headers) if headers
          req.body = body             if body
          yield req if block_given?
        end
      end

      def http_method(method, url = nil, body = nil, headers = nil)
        http.send(method) do |req|
          req.url(url)                if url
          req.headers.update(headers) if headers
          req.body = body             if body
          yield req if block_given?
        end
      end

      def faraday_options
        options = {
          :timeout => 6,
        }
      end

      def http(options = {})
        @http ||= begin
          Faraday.new(faraday_options.merge(options)) do |b|
            b.request :url_encoded
            b.request :json

            b.adapter :net_http
          end
        end
      end

      def erb(template, target_binding)
        ERB.new(template, nil, '-').result(target_binding)
      end

      def h(text)
        ERB::Util.h(text)
      end

      def unindent(string)
        indentation = string[/\A\s*/]
        string.strip.gsub(/^#{indentation}/, "") + "\n"
      end

      def smtp_settings
        {
          :address              => ENV['SMTP_SERVER'],
          :port                 => ENV['SMTP_PORT']           || 25,
          :authentication       => ENV['SMTP_AUTHENTICATION'] || :plain,
          :user_name            => ENV['SMTP_USERNAME']       || ENV['SENDGRID_USERNAME'],
          :password             => ENV['SMTP_PASSWORD']       || ENV['SENDGRID_PASSWORD'],
          :domain               => ENV['SMTP_DOMAIN']         || ENV['SENDGRID_DOMAIN'],
          :enable_starttls_auto => true
        }
      end

      def email_blacklist
        @blacklist ||= ENV['BLACKLISTED_EMAILS'].to_s.split(",").map {|a| a.downcase }
      end

      def sample_payload
        @helper.sample_payload
      end

      def raise_config_error(msg = "Invalid configuration")
        raise ConfigurationError, msg
      end

      def raise_error(msg = "Service Error")
        raise ServiceError, msg
      end

      # Gets the path to the SSL Certificate Authority certs.  These were taken
      # from: http://curl.haxx.se/ca/cacert.pem
      #def ca_file
      #  @ca_file ||= File.expand_path('../../../config/cacert.pem', __FILE__)
      #end

      class TimeoutError < StandardError; end
      class ServiceError < StandardError; end
      class ConfigurationError < StandardError; end
    end
  end
end

::Service = Librato::Services::Service

Dir[File.join(File.dirname(__FILE__), '../../services/*.rb')].each { |service|
  load service
}


