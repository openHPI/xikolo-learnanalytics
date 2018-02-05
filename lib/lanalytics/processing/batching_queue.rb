module Lanalytics
  module Processing
    class BatchingQueue

      def initialize(max_batch_size:, max_queue_time:)
        @max_batch_size = max_batch_size
        @max_queue_time = max_queue_time
        @queue = Queue.new
      end

      def on_flush(&block)
        @flush_block = block
      end

      def push(message)
        @queue << message
        if @queue.size == @max_batch_size
          cancel_scheduled_flush
          flush
        else
          schedule_flush unless flush_scheduled?
        end
      end

      private

      def flush_scheduled?
        %w(run sleep).include? @flush_thread&.status
      end

      def schedule_flush
        @flush_thread = Thread.new do
          sleep @max_queue_time
          flush
        end
      end

      def cancel_scheduled_flush
        if flush_scheduled?
          @flush_thread.exit
          @flush_thread = nil
        end
      end

      def flush
        n = [@queue.size, @max_batch_size].min
        messages = n.times.map{ @queue.pop }

        @flush_block.call messages unless @flush_block.nil?
      end
    end
  end
end