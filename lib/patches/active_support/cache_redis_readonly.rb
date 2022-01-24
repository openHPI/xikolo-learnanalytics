# frozen_string_literal: true

require 'active_support/cache'

module Patches
  module ActiveSupport
    module CacheRedisReadonly
      def failsafe(method, returning: nil)
        retryable = true

        begin
          super
        rescue ::Redis::CommandError => e
          if retryable && e.message.include?('READONLY')
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
