#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :irb do
  sh 'irb -I lib -r transit -I dev -r irb_tools'
end
