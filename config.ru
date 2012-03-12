require "rubygems"
require "bundler"

Bundler.require :default, :app

if ENV['REMOTE_SYSLOG_URI']
  uri = URI.parse(ENV['REMOTE_SYSLOG_URI'])
  logger = RemoteSyslogLogger::UdpSender.
    new(uri.host, uri.port,
        :local_hostname => "#{ENV['APP_NAME']}-#{ENV['PS']}")
  use Rack::CommonLogger, logger
end

# Add exception tracking middleware here to catch
# all exceptions from the following middleware.
#
if ENV["ERRBIT_API_KEY"]
  Airbrake.configure do |config|
    config.api_key = ENV['ERRBIT_API_KEY']
    config.host	   = ENV['ERRBIT_HOST']
    config.environment_name = ENV['RACK_ENV']
    config.port	   = 443
    config.secure  = config.port == 443
  end

  use Airbrake::Rack
end

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require "librato-services"

run Librato::Services::App
