# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

Xikolo::Lanalytics.rake = true

begin
  require 'geminabox/rake'
  Geminabox::Rake.install host: 'https://gemuser:QiKLoxr2rfPDisUmEYA9gnJGaLiWTuvW@dev.xikolo.de/gems/',
                          dir: '.', namespace: 'lanalytics-model'
rescue LoadError
end

namespace :ci do
  desc 'Setup service for CI'
  task setup: %w[db:drop:all db:create:all db:schema:load]

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
