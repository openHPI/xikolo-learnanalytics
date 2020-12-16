# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'lanalytics/s3'

Rails.application.load_tasks

namespace :ci do
  desc 'Setup service for CI'
  task setup: %w[ci:env db:drop:all db:create:all db:schema:load]

  desc 'Run specs for CI'
  task spec: %w[^spec]

  task :env do
    ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1'
  end
end

namespace :qc do
  desc 'Run all rules'
  task run_all_rules: :environment do
    QcRunAllRules.new.perform
    puts "finished"
  end
end

namespace :s3 do
  desc 'Create necessary S3 bucket(s) for reports (if it does not exist already)'
  task setup: :environment do
    reports = Lanalytics::S3.resource.bucket(
      Lanalytics.config.reports['s3_bucket'],
    )

    if reports.exists?
      puts "Bucket already exists. Done."
    else
      reports.create
      puts "Bucket created."
    end
  end
end

namespace :elastic do
  desc 'Create elasticsearch indexes and mappings (index must not exist)'
  task setup: :environment do
    interfaces = [
      Elasticsearch::ExpEventsInterface,
      Elasticsearch::LinkTrackingEventsInterface,
    ]

    interfaces.each do |interface|
      client       = interface.client
      index        = interface.index
      mapping      = interface.mapping
      mapping_json = ActiveSupport::JSON.encode mapping
      client.perform_request 'PUT', index, {}, mapping_json
    end
  end
end
