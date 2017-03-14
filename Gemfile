source 'https://gemuser:K6c1mcRWtrTQepS6aI8HRXc7DPoRYXbG@dev.xikolo.de/gems/'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2.5'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer',  platforms: :ruby, group: :production

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

gem 'rails-api'
gem 'xikolo-common', '~> 1.0'

gem 'xikolo-config', '~> 1.66'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'restify', '~> 0.5.0'
gem 'rails-rfc6570', '~> 0.3'

gem 'newrelic_rpm'

# Gems needed for the LAnalytics UI
gem 'slim'
gem 'forgery'
gem 'sorcery' # Authentication ...
gem 'validates_email_format_of'

# Connecting to RabbitMQ
gem 'msgr'
gem 'bunny', '< 1.5' # On production we are using an older RabbitMQ Version (2.XX); this is only supported by a bunny verion < 1.5

#  Needed for some hashing in DataTransformers ...
gem 'murmurhash3'

gem 'connection_pool'

# Different database adapters to store the data
gem 'neo4j-core'#, git: 'https://github.com/neo4jrb/neo4j-core', branch: 'master'
gem 'pg'
gem 'elasticsearch'
gem 'elasticsearch-transport'

gem 'rest-client'
gem 'multi_json'

gem 'ruby-progressbar'
gem 'link_header'


group :test do
  gem 'rspec-sidekiq'
end

gem 'business_time'
gem 'zip-zip'
gem 'zipruby-compat', :require => 'zipruby', :git => "https://github.com/jawspeak/zipruby-compatibility-with-rubyzip-fork.git", :tag => "v0.3.7"
gem 'rubyzip', '~> 1.1.0'
gem 'sidekiq'
gem 'sidekiq-cron'
gem 'database_cleaner'

gem 'xikolo-file', '~> 1.8.1'
gem 'xikolo-course', '~> 9.9.0'
gem 'xikolo-account'
gem 'xikolo-pinboard', '~> 4.39'
gem 'xikolo-helpdesk'
gem 'xikolo-quiz'
gem 'xikolo-richtext'
gem 'xikolo-submission'
gem 'xikolo-video'

# Xikolo service clients
gem 'acfs', '= 0.42'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

gem 'geoip' # Location tracking

gem 'browser' # Browser info

gem 'uuid4'

gem 'rserve-client', '~> 0.3.1' # Connect ruby to R

gem 'responders'
gem 'api-responder'
gem 'decorate-responder'
gem 'will_paginate'
gem 'paginate-responder'
gem 'draper'
gem 'mechanize'
gem 'axlsx'
gem 'axlsx_rails'

# for versioning
gem 'paper_trail'


# Asynchronous execution + cache in redis
gem 'redis-activesupport'

group :development, :test do
  gem 'rspec-rails'#, '~> 3.0.0'
  gem 'rspec-collection_matchers'
  gem 'factory_girl_rails'
  gem 'rspec-its'
end

group :development do
  gem 'spring' # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'os'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'

  # To release the lanalytics-model gem
  gem 'geminabox-rake', '~> 1.1.0'

  gem 'ruby-prof' # To do performance evaluation

  gem 'pry-byebug'
end

group :test do
  gem 'webmock'
  gem 'simplecov'
  gem 'accept_values_for'
end

group :test, :integration do
  gem 'rack-remote'
end

