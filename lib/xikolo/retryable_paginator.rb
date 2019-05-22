module Xikolo
  class RetryablePaginator
    def initialize(max_retries:, wait:, &request)
      @max_retries = max_retries
      @wait = wait
      @request = request

      @first_page = start(&request)
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

        current_page = start { current_page.rel(:next).get }.value!.first
      end
    end

    private

    def start(&request_blk)
      RetryingPromise.new(
        Retryable.new(
          max_retries: @max_retries,
          wait: @wait,
          &request_blk
        )
      )
    end
  end
end
