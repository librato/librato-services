# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "librato-services"
  s.version = "2.27.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mike Heffner"]
  s.date = "2014-10-15"
  s.description = "Provides service notifications for alerts"
  s.email = "mike@librato.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".travis.yml",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "Procfile",
    "README.md",
    "Rakefile",
    "VERSION",
    "config.ru",
    "dot.rvmrc",
    "lib/librato-services.rb",
    "lib/librato-services/authentication.rb",
    "lib/librato-services/helpers/alert_helpers.rb",
    "lib/librato-services/helpers/snapshot_helpers.rb",
    "lib/librato-services/output.rb",
    "lib/librato-services/service.rb",
    "librato-services.gemspec",
    "services/campfire.rb",
    "services/customer-io.rb",
    "services/flowdock.rb",
    "services/hipchat.rb",
    "services/mail.rb",
    "services/opsgenie.rb",
    "services/pagerduty.rb",
    "services/slack.rb",
    "services/webhook.rb",
    "test/campfire_test.rb",
    "test/clearing_test.rb",
    "test/customer_io_test.rb",
    "test/flowdock_test.rb",
    "test/helper.rb",
    "test/hipchat_test.rb",
    "test/mail_test.rb",
    "test/opsgenie_test.rb",
    "test/output_test.rb",
    "test/pagerduty_test.rb",
    "test/slack_test.rb",
    "test/timeout_service_test.rb",
    "test/webhook_test.rb"
  ]
  s.homepage = "http://github.com/librato/librato-services"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23.2"
  s.summary = "Provides service notifications for alerts"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<faraday>, ["~> 0.8"])
      s.add_runtime_dependency(%q<tilt>, ["~> 1"])
      s.add_runtime_dependency(%q<yajl-ruby>, ["~> 1.1"])
      s.add_runtime_dependency(%q<activesupport>, [">= 3.2"])
      s.add_runtime_dependency(%q<mail>, ["~> 2.2"])
      s.add_runtime_dependency(%q<tinder>, ["~> 1.9"])
      s.add_runtime_dependency(%q<hipchat-api>, ["~> 1.0"])
      s.add_runtime_dependency(%q<flowdock>, ["~> 0.3"])
      s.add_runtime_dependency(%q<customerio>, ["~> 0.5"])
      s.add_runtime_dependency(%q<redcarpet>, ["~> 2.3"])
      s.add_runtime_dependency(%q<rake>, [">= 0.9"])
      s.add_development_dependency(%q<shoulda>, ["~> 3.5"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0"])
      s.add_development_dependency(%q<yard>, ["~> 0.8"])
      s.add_development_dependency(%q<package_cloud>, ["~> 0.2"])
    else
      s.add_dependency(%q<faraday>, ["~> 0.8"])
      s.add_dependency(%q<tilt>, ["~> 1"])
      s.add_dependency(%q<yajl-ruby>, ["~> 1.1"])
      s.add_dependency(%q<activesupport>, [">= 3.2"])
      s.add_dependency(%q<mail>, ["~> 2.2"])
      s.add_dependency(%q<tinder>, ["~> 1.9"])
      s.add_dependency(%q<hipchat-api>, ["~> 1.0"])
      s.add_dependency(%q<flowdock>, ["~> 0.3"])
      s.add_dependency(%q<customerio>, ["~> 0.5"])
      s.add_dependency(%q<redcarpet>, ["~> 2.3"])
      s.add_dependency(%q<rake>, [">= 0.9"])
      s.add_dependency(%q<shoulda>, ["~> 3.5"])
      s.add_dependency(%q<jeweler>, ["~> 2.0"])
      s.add_dependency(%q<yard>, ["~> 0.8"])
      s.add_dependency(%q<package_cloud>, ["~> 0.2"])
    end
  else
    s.add_dependency(%q<faraday>, ["~> 0.8"])
    s.add_dependency(%q<tilt>, ["~> 1"])
    s.add_dependency(%q<yajl-ruby>, ["~> 1.1"])
    s.add_dependency(%q<activesupport>, [">= 3.2"])
    s.add_dependency(%q<mail>, ["~> 2.2"])
    s.add_dependency(%q<tinder>, ["~> 1.9"])
    s.add_dependency(%q<hipchat-api>, ["~> 1.0"])
    s.add_dependency(%q<flowdock>, ["~> 0.3"])
    s.add_dependency(%q<customerio>, ["~> 0.5"])
    s.add_dependency(%q<redcarpet>, ["~> 2.3"])
    s.add_dependency(%q<rake>, [">= 0.9"])
    s.add_dependency(%q<shoulda>, ["~> 3.5"])
    s.add_dependency(%q<jeweler>, ["~> 2.0"])
    s.add_dependency(%q<yard>, ["~> 0.8"])
    s.add_dependency(%q<package_cloud>, ["~> 0.2"])
  end
end

