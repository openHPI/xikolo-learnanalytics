# Sidekiq must be loaded before call of load_cron via puppet.rb initializer
# (deployed via puppet)
# Note that we will keep the old file cause puppet will not delete config files

def load_cron_jobs
  cron_file = 'config/cron.yml'
  if File.exists? cron_file
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(cron_file)
  end
end

unless Rails.env.production?
  Sidekiq.configure_server do |config|
    config.redis = {namespace: 'xikolo-services-lanalytics'}
    load_cron_jobs
  end

  Sidekiq.configure_client do |config|
    config.redis = {namespace: 'xikolo-services-lanalytics'}
  end
end
