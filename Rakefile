require 'bundler'
require 'bundler/gem_tasks'

task :spec do
  require File.expand_path('spec/run')
end

begin
  require 'kitchen/rake_tasks'
  Kitchen::RakeTasks.new
rescue LoadError
  puts '>>>>> Kitchen gem not loaded, omitting tasks' unless ENV['CI']
end
