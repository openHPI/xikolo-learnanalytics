# frozen_string_literal: true

require 'sidekiq/client'

module Patches
  module Sidekiq
    module ClientRedisReadonly
      private

      def raw_push(payloads)
        @redis_pool.with do |conn|
          retryable = true

          begin
            conn.pipelined do
              atomic_push(conn, payloads)
            end
            true
          rescue ::Redis::CommandError => e
            if retryable && e.message =~ /READONLY|NOREPLICAS|UNBLOCKED/
              conn.disconnect!
              retryable = false
              retry
            end
            raise
          end
        end
      end

      ::Sidekiq::Client.prepend self
    end
  end
end
