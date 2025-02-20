# frozen_string_literal: true

module Xikolo
  # An Progress object manages task progress based on multiple, individual
  # counters. Each counter has their own current and maximum values, both can be
  # updated at any time.
  #
  # A summary can be requested providing a single snapshot of the current,
  # global progress. All access to the progress manager is thread-safe and
  # synchronized.
  #
  # An optional block can be given to the initializer that will be called
  # whenever the progress is updated.
  #
  # Example:
  #
  #     progress = Xikolo::Progress.new
  #     progress.update('Task 1', 0, max: 100)
  #     progress.update('Task 2', 50, max: 100)
  #     progress.get.to_f # => 0.25
  #
  class Progress
    def initialize(&block)
      @mutex = ::Mutex.new
      @current = {}
      @maximum = {}
      @callback = block
    end

    def update(id, current, max: nil)
      summary = @mutex.synchronize do
        @current[id] = current
        @maximum[id] = max if max

        ns_get if @callback
      end

      @callback&.call(summary)
    end

    def get
      @mutex.synchronize { ns_get }
    end

    Summary = Struct.new(:value, :total) do
      def to_f
        (value.to_f / total).clamp(0, 1)
      end

      def percentage
        to_f * 100
      end

      def to_i
        percentage.round
      end
    end

    private

    def ns_get
      Summary.new(@current.values.sum, @maximum.values.sum)
    end
  end
end
