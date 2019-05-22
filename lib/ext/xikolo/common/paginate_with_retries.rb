# frozen_string_literal: true

module Xikolo::Common::PaginateWithRetries
  def paginate_with_retries(**opts, &block)
    Xikolo::RetryablePaginator.new(**opts, &block)
  end
end
