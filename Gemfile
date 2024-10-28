# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 3.3.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1'

gem 'puma'

gem 'base64'
gem 'csv'
gem 'drb'
gem 'mutex_m'
gem 'nokogiri', '~> 1.11'
gem 'syslog'
gem 'uuid4'

gem 'browser'
gem 'connection_pool'
gem 'iso_country_codes'
gem 'maxminddb'

# Rails plugins
gem 'decorate-responder'
gem 'draper'
gem 'link_header'
gem 'paginate-responder'
gem 'paper_trail', '~> 15.0' # for versioning
gem 'rails-rfc6570', '~> 3.0'
gem 'responders'
gem 'will_paginate'

# Messaging and background jobs
gem 'msgr', '~> 1.5'
gem 'sidekiq', '~> 7.0'
gem 'sidekiq-cron', '~> 1.4'

# Databases and clients
gem 'aws-sdk-s3', '~> 1.16'
gem 'elasticsearch', '~> 7.13.1'
gem 'elasticsearch-transport', '~> 7.13.1'
gem 'pg', '~> 1.1'
gem 'redis', '~> 5.0'
gem 'restify', '~> 1.15'

# Monitoring and metrics
gem 'mnemosyne-ruby', '~> 2.0'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'sentry-sidekiq'
gem 'telegraf', '~> 3.0'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'memory_profiler'
  gem 'os'
  gem 'ruby-prof' # To do performance evaluation
end

group :development, :test do
  gem 'database_cleaner'
  gem 'factory_bot_rails', '~> 6.0'
  gem 'listen'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rspec', '~> 3.10'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'rspec-sidekiq'
  gem 'rspec-teamcity', require: false
  gem 'rubocop', '~> 1.67.0'
  gem 'rubocop-factory_bot', '~> 2.26.1'
  gem 'rubocop-performance', '~> 1.22.0'
  gem 'rubocop-rails', '~> 2.27.0'
  gem 'rubocop-rspec', '~> 3.2.0'
  gem 'simplecov'
  gem 'timecop'
  gem 'webmock'
end

group :test, :integration do
  gem 'rack-remote'
end
