# frozen_string_literal: true

require 'csv'
require 'file_collection'
require 'lanalytics'

module Reports
  class Base
    class << self
      def queue_name
        @queue_name || :reports_default
      end

      protected

      def queue_as(queue_name)
        @queue_name = queue_name
      end
    end

    def initialize(job)
      # Subclasses can override this method if they need access to
      # the additional options
      @job = job

      @machine_headers = job.options['machine_headers']
    end

    def files
      @files ||= FileCollection.new(@job.tmp_directory)
    end

    def escape_csv_string(string)
      "\"#{string}\""
    end

    class InvalidReportArgumentError < ArgumentError
      def initialize(name, value)
        super()
        @name = name
        @value = value
      end

      def message
        "Invalid value '#{@value}' for argument '#{@name}'."
      end
    end

    private

    def csv_file(target, headers, &block)
      CSV.open(
        files.make(
          "#{target}_#{DateTime.now.strftime('%Y-%m-%d')}_#{@job.id}.csv",
        ),
        'wb',
      ) do |csv|
        csv << if @machine_headers
                 # Lowercase, underscored (incl. whitespaces) and
                 # non-alphanumeric characters removed.
                 headers.map {|h| h.underscore.tr(' ', '_').gsub(/\W/, '') }
               else
                 headers
               end

        index = 0

        # rubocop:disable Performance/RedundantBlockCall
        block.call do |row|
          csv << row
          csv.flush

          Lanalytics.telegraf.write(
            'report_jobs',
            tags: {id: @job.id, type: @job.task_type},
            values: {
              user_id: @job.user_id,
              status: 'line_flushed',
              line: index,
            },
          )

          index += 1
        end
        # rubocop:enable all
      end
    end
  end
end
