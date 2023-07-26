# frozen_string_literal: true

module Xikolo
  module Paginate
    require 'xikolo/paginate/paginator'
    require 'xikolo/paginate/retrying_paginator'

    def paginate_with_retries(...)
      RetryingPaginator.new(...)
    end

    def paginate(request, &block)
      paginator = Paginator.new(request)

      if block_given?
        paginator.each_item(&block)
      else
        paginator
      end
    end
  end

  ::Xikolo.send :extend, Paginate
end
