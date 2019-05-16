module Xikolo
  class RetryablePaginator
    def initialize(retryable)
      @retryable  = retryable
      @first_page = RetryingPromise.new(retryable)
    end

    def each_item(&block)
      each_page do |page|
        page.each do |item|
          block.call item, page
        end
      end
    end

    def each_page(&block)
      current_page = @first_page.value!.first

      loop do
        block.call current_page

        break unless current_page.rel?(:next)

        current_page = RetryingPromise.new(
          Retryable.new(
            max_retries: @retryable.max_retries,
            wait: @retryable.wait
          ) { current_page.rel(:next).get }
        ).value!.first
      end
    end
  end
end
