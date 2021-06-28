# frozen_string_literal: true

module Xikolo
  class RetryingPromise
    def initialize(*dependencies, &task)
      @task         = task
      @dependencies = dependencies.flatten
    end

    def value!
      loop do
        @dependencies.each do |dep|
          dep.value!
        rescue Restify::GatewayError, Restify::Timeout::Error => e
          ::Mnemosyne.attach_error(e)
          ::Sentry.capture_exception(e)
          dep.retry!
        end

        break if @dependencies.all?(&:success?)
      end

      values = @dependencies.map(&:value!)

      @task ? @task.call(*values) : values
    end
  end
end
