# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require File.expand_path('config/application', __dir__)

require 'lanalytics/s3'

Lanalytics::Application.load_tasks

namespace :ci do
  desc 'Setup service for CI'
  task setup: %w[ci:env db:drop:all db:create:all db:schema:load]

  desc 'Run specs for CI'
  task spec: %w[^spec]

  task env: :environment do
    ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1'
  end
end

namespace :s3 do
  desc 'Create necessary S3 bucket(s) for reports (if it does not exist already)'
  task setup: :environment do
    reports = Lanalytics::S3.resource.bucket(
      Lanalytics.config.reports['s3_bucket'],
    )

    if reports.exists?
      puts 'Bucket already exists. Done.'
    else
      reports.create
      puts 'Bucket created.'
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

      puts "Created Elasticsearch index #{index}"
    end
  end

  desc 'Deletes elasticsearch indexes and mappings'
  task delete: :environment do
    interfaces = [
      Elasticsearch::ExpEventsInterface,
      Elasticsearch::LinkTrackingEventsInterface,
    ]

    interfaces.each do |interface|
      client       = interface.client
      index        = interface.index
      client.perform_request 'DELETE', index

      puts "Deleted Elasticsearch index #{index}"
    end
  end

  desc 'Deletes and creates elasticsearch indexes and mappings'
  task reset: %i[delete setup]
end
