module Xikolo
  class Retryable
    attr_reader :max_retries, :wait

    def initialize(max_retries:, wait:, &promise_block)
      @max_retries = max_retries
      @wait = wait
      @promise_block = promise_block
      @promise = @promise_block.call
      @retry_count = 0
    end

    def retry!
      raise 'Maximum number of retries already executed!' unless retryable?

      sleep @wait.to_i
      @retry_count += 1
      @promise = @promise_block.call
    end

    def retryable?
      @retry_count < @max_retries
    end

    def value!
      @promise.value!
    end

    def success?
      @promise.fulfilled? && @promise.value.response.success?
    end
  end
end
