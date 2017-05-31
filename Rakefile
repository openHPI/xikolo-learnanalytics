# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

Xikolo::Lanalytics.rake = true

begin
  require 'geminabox/rake'
  Geminabox::Rake.install host: 'https://gemuser:K6c1mcRWtrTQepS6aI8HRXc7DPoRYXbG@dev.xikolo.de/gems/',
                          dir: '.', namespace: 'lanalytics-model'
rescue LoadError
end

namespace :sidekiq do
  desc 'Clear sidekiq queue'
  task clear: :environment do
    require 'sidekiq/api'
    Sidekiq::Queue.new.clear
    Sidekiq::RetrySet.new.clear
  end
end

namespace :ci do
  desc 'Setup service for CI'
  task setup: %w(db:drop db:create:all db:setup) do
  end

  desc 'Run specs for CI'
  task spec: %w(^default) do
  end
end

namespace :qc do
  desc 'Run all rules'
  task run_all_rules: :environment do
    QcRunAllRules.new.perform
    puts "finished"
  end
end
