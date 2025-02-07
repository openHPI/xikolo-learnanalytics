# frozen_string_literal: true

module Xikolo::Paginate
  class RetryingPaginator
    def initialize(max_retries:, wait:, &request)
      @max_retries = max_retries
      @wait = wait
      @request = request

      @first_page = start(&request)
    end

    def each_item
      each_page do |page|
        page.each do |item|
          yield item, page
        end
      end
    end

    def each_page
      current_page = @first_page.value!.first

      loop do
        yield current_page

        break unless current_page.rel?(:next)

        current_page = start { current_page.rel(:next).get }.value!.first
      end
    end

    private

    def start(&)
      Xikolo::RetryingPromise.new(
        Xikolo::Retryable.new(
          max_retries: @max_retries,
          wait: @wait,
          &
        ),
      )
    end
  end
end
