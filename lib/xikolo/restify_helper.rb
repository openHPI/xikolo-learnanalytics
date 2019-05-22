module Xikolo
  class RestifyHelper
    def self.retryable_paginate(**opts, &block)
      RetryablePaginator.new(**opts, &block)
    end
  end
end
