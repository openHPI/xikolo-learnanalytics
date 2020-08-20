# frozen_string_literal: true

module Xikolo
  module Reconnect
    ##
    # Execute a database query, and retry it once if the connection is stale.
    #
    # Useful for long-running batch jobs that can sometimes idle for a long
    # time when waiting for HTTP requests or retries.
    #
    def self.on_stale_connection
      attempts = 1

      begin
        yield
      rescue ActiveRecord::StatementInvalid => e
        raise unless e.cause.is_a? PG::ConnectionBad

        ActiveRecord::Base.connection.reconnect!
        attempts += 1

        # Multiple exceptions of the same type probably point to a deeper
        # problem - retries probably won't help here.
        raise if attempts > 2

        retry
      end
    end
  end
end
