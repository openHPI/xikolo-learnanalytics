# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 2.7.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1'

gem 'bundler', '~> 2.0'

gem 'nokogiri', '~> 1.11'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

gem 'rails-rfc6570', '~> 2.3'
gem 'restify', '~> 1.15'

gem 'concurrent-ruby', '~> 1.0'
gem 'mnemosyne-ruby', '~> 1.12'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'sentry-sidekiq'
gem 'telegraf', '~> 1.0'

gem 'forgery'
gem 'validates_email_format_of'

# Connecting to RabbitMQ
gem 'msgr', '~> 1.3'

gem 'connection_pool'

# Different storage backends for data and files
gem 'aws-sdk-s3', '~> 1.16'
gem 'elasticsearch'
gem 'elasticsearch-transport'
gem 'pg', '~> 1.1'
gem 'redis', '~> 4.0'

gem 'multi_json'
gem 'rest-client'

gem 'link_header'
gem 'ruby-progressbar'

gem 'business_time'
gem 'database_cleaner'
gem 'sidekiq', '~> 6.0'
gem 'sidekiq-cron'

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
gem 'paper_trail', '~> 12.0'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'memory_profiler'
  gem 'os'
  gem 'pry-byebug'
  gem 'ruby-prof' # To do performance evaluation
  gem 'spring' # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
end

group :development, :test do
  gem 'factory_bot_rails', '~> 6.0'
  gem 'listen'
  gem 'rspec', '~> 3.7'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'rspec-teamcity', require: false
  gem 'rubocop', '~> 1.22.0'
  gem 'rubocop-performance', '~> 1.11.3'
  gem 'rubocop-rails', '~> 2.12.0'
  gem 'rubocop-rspec', '~> 2.5.0'
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
