# frozen_string_literal: true

threads_count = ENV.fetch('RAILS_MAX_THREADS', 16)
threads threads_count, threads_count

environment ENV.fetch('RAILS_ENV', 'production')

# workers ENV.fetch("WEB_CONCURRENCY") { 2 }
# preload_app!

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end

plugin :tmp_restart
