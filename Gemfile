# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 3.2.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1'

gem 'nokogiri', '~> 1.11'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

gem 'rails-rfc6570', '~> 3.0'
gem 'restify', '~> 1.15'

gem 'concurrent-ruby', '~> 1.0'
gem 'mnemosyne-ruby', '~> 1.16'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'sentry-sidekiq'
gem 'telegraf', '~> 2.0'

gem 'forgery'
gem 'validates_email_format_of'

# Connecting to RabbitMQ
gem 'msgr', '~> 1.5'

gem 'connection_pool'

# Different storage backends for data and files
gem 'aws-sdk-s3', '~> 1.16'
gem 'elasticsearch', '~> 7.13.1'
gem 'elasticsearch-transport', '~> 7.13.1'
gem 'pg', '~> 1.1'
gem 'redis', '~> 5.0'

gem 'multi_json'
gem 'rest-client'

gem 'link_header'
gem 'ruby-progressbar'

gem 'business_time'
gem 'database_cleaner'
gem 'sidekiq', '~> 7.0'
gem 'sidekiq-cron', '~> 1.4'

# Use unicorn as the app server
gem 'unicorn'
gem 'unicorn-rails'

gem 'iso_country_codes' # converting ISO country codes
gem 'maxminddb' # Location tracking

gem 'browser' # Browser info

gem 'uuid4'

gem 'decorate-responder'
gem 'draper'
gem 'mechanize'
gem 'paginate-responder'
gem 'responders'
gem 'will_paginate'

# for versioning
gem 'paper_trail', '~> 15.0'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'memory_profiler'
  gem 'os'
  gem 'pry-byebug'
  gem 'ruby-prof' # To do performance evaluation
end

group :development, :test do
  gem 'factory_bot_rails', '~> 6.0'
  gem 'listen'
  gem 'rspec', '~> 3.10'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'rspec-teamcity', require: false
  gem 'rubocop', '~> 1.56.0'
  gem 'rubocop-performance', '~> 1.19.0'
  gem 'rubocop-rails', '~> 2.21.0'
  gem 'rubocop-rspec', '~> 2.24.0'
end

group :test do
  gem 'accept_values_for'
  gem 'rspec-sidekiq'
  gem 'simplecov'
  gem 'timecop'
  gem 'webmock'
end

group :test, :integration do
  gem 'rack-remote'
end
