# frozen_string_literal: true

# Application Unicorn Configuration

worker_processes ENV.fetch('WORKER', 1).to_i

logger Logger.new(STDOUT)
preload_app true
check_client_connection false

before_fork do |server, _worker|
  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.connection.disconnect!

  defined?(Msgr) && Msgr.client.stop

  old_pid = "#{server.pid}.oldbin"
  if File.exist?(old_pid) && server.pid != old_pid
    begin
      Process.kill('QUIT', File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |_server, _worker|
  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.establish_connection

  defined?(Msgr) && Msgr.start
end
