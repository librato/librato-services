require "rubygems"
require "bundler"

Bundler.require

# if ENV['REMOTE_SYSLOG_URI']
#   uri = URI.parse(ENV['REMOTE_SYSLOG_URI'])
#   logger = RemoteSyslogLogger::UdpSender.
#     new(uri.host, uri.port,
#         :local_hostname => "#{ENV['APP_NAME']}-#{ENV['PS']}")
#   use Rack::CommonLogger, logger
# end

require "lib/librato-services"
run Librato::Services::App
