source 'https://gemuser:QiKLoxr2rfPDisUmEYA9gnJGaLiWTuvW@dev.xikolo.de/gems/'
ruby '~> 2.7.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.0'

gem 'bundler', '~> 2.0'

# 1.8.3+ does not compile
gem 'nokogiri', '< 1.8.3'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

gem 'xikolo-common', '~> 2.4'

gem 'restify', '~> 1.8'
gem 'rails-rfc6570', '~> 2.3'

gem 'concurrent-ruby', '~> 1.0'
gem 'mnemosyne-ruby', '~> 1.3'
gem 'sentry-raven', '~> 2.11'
gem 'telegraf', '~> 0.7.0'

gem 'forgery'
gem 'validates_email_format_of'

# Connecting to RabbitMQ
gem 'msgr', '~> 1.3'

gem 'connection_pool'

# Different storage backends for data and files
gem 'pg', '~> 1.1'
gem 'redis', '~> 4.0'
gem 'elasticsearch'
gem 'elasticsearch-transport'
gem 'aws-sdk-s3', '~> 1.16'

gem 'rest-client'
gem 'multi_json'

gem 'ruby-progressbar'
gem 'link_header'

gem 'business_time'
gem 'xikolo-sidekiq', '~> 3.0'
gem 'sidekiq-cron'
gem 'database_cleaner'

# Use unicorn as the app server
gem 'unicorn'

gem 'maxminddb' # Location tracking
gem 'iso_country_codes' #converting ISO country codes

gem 'browser' # Browser info

gem 'uuid4'

gem 'responders'
gem 'decorate-responder'
gem 'will_paginate'
gem 'paginate-responder'
gem 'draper'
gem 'mechanize'

# for versioning
gem 'paper_trail'

group :development do
  gem 'spring' # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'os'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'

  gem 'ruby-prof' # To do performance evaluation

  gem 'pry-byebug'
end

group :development, :test do
  gem 'factory_bot_rails', '~> 4.0'
  gem 'listen'
  gem 'pronto'
  gem 'pronto-rubocop', require: false
  gem 'rspec', '~> 3.7'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'rspec-teamcity', require: false
  gem 'xikolo-lint', '~> 2.2.0'
end

group :test do
  gem 'webmock'
  gem 'simplecov'
  gem 'accept_values_for'
  gem 'rspec-sidekiq'
  gem 'timecop'
end

group :test, :integration do
  gem 'rack-remote'
end
