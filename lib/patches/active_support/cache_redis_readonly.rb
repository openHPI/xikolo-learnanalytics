# frozen_string_literal: true

require 'active_support/cache'

module Patches
  module ActiveSupport
    module CacheRedisReadonly
      def failsafe(method, returning: nil)
        retryable = true

        super(method, returning: returning) do
          yield
        rescue ::Redis::ReadOnlyError, ::RedisClient::ReadOnlyError
          if retryable
            redis.respond_to?(:disconnect!) ? redis.disconnect! : redis.reload { nil }
            retryable = false
            retry
          end

          raise
        end
      end

      ::ActiveSupport::Cache::RedisCacheStore.prepend self
    end
  end
end
