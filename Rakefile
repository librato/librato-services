# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
t = Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "librato-services"
  gem.homepage = "http://github.com/librato/librato-services"
  gem.license = "MIT"
  gem.summary = %Q{Provides service notifications for alerts}
  gem.description = %Q{Provides service notifications for alerts}
  gem.email = "mike@librato.com"
  gem.authors = ["Mike Heffner"]
  # dependencies defined in Gemfile
end
jeweler = t.jeweler
Jeweler::RubygemsDotOrgTasks.new

#
# XXX: Rake does not provide a way to remove a task
#
Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

def remove_task(task_name)
  Rake.application.remove_task(task_name)
end

# We don't want to release to rubygems
remove_task :release
desc "Build gemspec, commit, and then git/tag push."
task :release => ['gemspec:release', 'git:release', :package_cloud ]

desc "Push gem to package_cloud"
task :package_cloud do
  # Dig into jeweler's guts to get the gem file name
  gemspec_helper = jeweler.gemspec_helper
  gemspec_helper.update_version(jeweler.version_helper) unless gemspec_helper.has_version?
  gemspec = gemspec_helper.parse

  gem_file_name = if Gem::Version.new(`gem -v`) >= Gem::Version.new("2.0.0.a")
    Gem::Package.build(gemspec)
  else
    require "rubygems/builder"
    Gem::Builder.new(gemspec).build
  end

  gem_file_path = File.join(jeweler.base_dir, gem_file_name)

  sh "package_cloud push librato/rubygems #{gem_file_path}"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => :test

# Docs
require 'yard'
YARD::Rake::YardocTask.new
