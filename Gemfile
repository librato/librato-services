source "http://rubygems.org"

gem 'sinatra', '~> 1.2.6'

# XXX: Need > 0.7.4, switch back to gem when 0.7.5 is released
gem 'faraday', :git => 'https://github.com/technoweenie/faraday.git'

gem 'activesupport', '~> 2.3', :require => 'active_support'
gem 'yajl-ruby', :require => [ 'yajl', 'yajl/json_gem' ]

gem 'hoptoad_notifier'

# service: mail
gem 'mail', '~> 2.2'

# service :campfire
gem 'tinder', '~> 1.7'

# Ensure everyone plays nice with SSL
#
gem 'always_verify_ssl_certificates', '~> 0.3.0'

gem 'unicorn'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "thin", "~> 1.2.11"
  gem "shotgun", "~> 0.8"
  gem "shoulda", ">= 0"
  gem "bundler", "~> 1.0.0"
  gem "jeweler", "~> 1.6.4"
  gem "rcov", ">= 0"
end
