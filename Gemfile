source "http://rubygems.org"

gem 'faraday', '~> 0.8'
gem 'tilt',  '~> 1'

gem 'yajl-ruby', '~> 1.1', :require => [ 'yajl', 'yajl/json_gem' ]
gem 'activesupport', '>= 3.2', :require => 'active_support'

# service: mail
gem 'mail', '~> 2.2'

# service :campfire
gem 'tinder', '~> 1.9'

# service :hipchat
gem 'hipchat', '~> 1.4.0'

# service :flowdock
gem 'flowdock', '~> 0.3'

# service :aws-sns
gem 'aws-sdk-core', '~> 2.0.18'

# markdown generation
gem 'redcarpet', '~> 2.3'

# Ensure everyone plays nice with SSL
#
#gem 'always_verify_ssl_certificates', '~> 0.3.0'

gem 'rake', '>= 0.9'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "rspec", "~>3.1"
  gem "shoulda", "~> 3.5"
  gem "jeweler", "~> 2.0"
  gem 'yard', "~> 0.8"
end
