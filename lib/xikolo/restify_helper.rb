module Xikolo
  class RestifyHelper
    def self.retryable_paginate(retryable, &block)
      paginator = RetryablePaginator.new(retryable)

      if block_given?
        paginator.each_item(&block)
      else
        paginator
      end
    end
  end
end
