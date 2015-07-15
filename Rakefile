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
