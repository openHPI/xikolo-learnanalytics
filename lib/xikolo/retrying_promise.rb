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
        rescue Restify::ServerError => e
          if (502..504) === e.response.code
            ::Mnemosyne.attach_error(e)
            ::Raven.capture_exception(e)
            dep.retry!
          else
            raise
          end
        end

        break if @dependencies.all?(&:success?)
      end

      values = @dependencies.map(&:value!)

      @task ? @task.call(*values) : values
    end
  end
end
