source 'https://gemuser:QiKLoxr2rfPDisUmEYA9gnJGaLiWTuvW@dev.xikolo.de/gems/'
ruby '~> 2.5.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.0'

# 1.8.3+ does not compile
gem 'nokogiri', '< 1.8.3'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

gem 'xikolo-common', '~> 2.4'
gem 'xikolo-config', '~> 2.41'
gem 'xikolo-s3', '~> 1.0'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'restify', '~> 1.8'
gem 'rails-rfc6570', '~> 2.3'

gem 'mnemosyne-ruby', '~> 1.3'

gem 'forgery'
gem 'validates_email_format_of'

# Connecting to RabbitMQ
gem 'msgr', '~> 1.0'

gem 'connection_pool'

# Different database adapters to store the data
gem 'pg', '~> 1.1'
gem 'elasticsearch'
gem 'elasticsearch-transport'

# Google Analytics Reporting API
gem 'google-api-client', '~> 0.19.7'

# Check availability of Google Analytics API
gem 'net-ping', '~> 1.7', '>= 1.7.8'

gem 'rest-client'
gem 'multi_json'

gem 'ruby-progressbar'
gem 'link_header'

gem 'business_time'
gem 'xikolo-sidekiq'
gem 'sidekiq-cron'
gem 'database_cleaner'

# Use unicorn as the app server
gem 'unicorn'

gem 'geoip' # Location tracking
gem 'iso_country_codes' #converting ISO country codes

gem 'browser' # Browser info

gem 'uuid4'

gem 'rserve-client', '~> 0.3.1' # Connect ruby to R

gem 'responders'
gem 'decorate-responder'
gem 'will_paginate'
gem 'paginate-responder'
gem 'draper'
gem 'mechanize'

# for versioning
gem 'paper_trail'

# Asynchronous execution + cache in redis
gem 'redis-activesupport'

group :development do
  gem 'spring' # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'os'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'

  # To release the lanalytics-model gem
  gem 'geminabox-rake', '~> 1.1'

  gem 'ruby-prof' # To do performance evaluation

  gem 'pry-byebug'
end

group :development, :test do
  gem 'listen'
  gem 'factory_bot_rails', '~> 4.0'
  gem 'rspec', '~> 3.7'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'rspec-teamcity', require: false
end

group :test do
  gem 'webmock'
  gem 'simplecov'
  gem 'accept_values_for'
  gem 'rspec-sidekiq'
end

group :test, :integration do
  gem 'rack-remote'
end
