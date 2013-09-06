source "http://rubygems.org"

gem 'sinatra', '~> 1.2.7'

gem 'faraday', '~> 0.8.4'

gem 'activesupport', '~> 3.2.8', :require => 'active_support'
gem 'yajl-ruby', :require => [ 'yajl', 'yajl/json_gem' ]

# Remote system logging
gem 'remote_syslog_logger', '~> 1.0.3'

# service: mail
gem 'mail', '~> 2.2'

# service :campfire
gem 'tinder', '~> 1.9.1'

# service :hipchat
gem 'hipchat-api', '~> 1.0.4'

# service :flowdock
gem 'flowdock', '~> 0.3.1'

# service :customerio
gem 'customerio', '~> 0.5.0'

# Ensure everyone plays nice with SSL
#
#gem 'always_verify_ssl_certificates', '~> 0.3.0'

gem 'rake', '~>0.9.2.2'

group :app do
  gem 'airbrake', '~> 3.0.9', :require => false

  gem 'honeybadger', '~> 1.6.1', :require => false

  # New Relic
  # gem 'newrelic_rpm', '~> 3.3.0'

  gem 'unicorn'
end

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "thin", "~> 1.5.0"
  gem "shotgun", "~> 0.8"
  gem "shoulda", ">= 0"
  gem "jeweler", "~> 1.6.4"
  gem "rcov", ">= 0"
  gem 'yard'
end
