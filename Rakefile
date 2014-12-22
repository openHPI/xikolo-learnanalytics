# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

Lanalytics.rake = true

if Rails.env.development?
  require 'geminabox/rake'
  Geminabox::Rake.install host: 'https://gemuser:K6c1mcRWtrTQepS6aI8HRXc7DPoRYXbG@openhpi-utils.hpi.uni-potsdam.de/gems/',
                          dir: '.',
                          namespace: 'lanalytics-model'
end

