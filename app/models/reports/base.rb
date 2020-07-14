require 'csv'
require 'file_collection'

module Reports
  class Base
    def initialize(job)
      # Subclasses can override this method if they need access to the additional options
      @job = job

      @machine_headers = job.options['machine_headers']
    end

    def files
      @files ||= FileCollection.new(@job.tmp_directory)
    end

    def escape_csv_string(string)
      "\"#{string}\""
    end

    private

    def csv_file(target, headers, &block)
      CSV.open(
        files.make("#{target}_#{DateTime.now.strftime('%Y-%m-%d')}_#{@job.id}.csv"),
        'wb'
      ) do |csv|
        if @machine_headers
          csv << headers.map(&:underscore)
        else
          csv << headers
        end

        index = 0

        block.call do |row|
          csv << row
          csv.flush

          Xikolo.metrics.write(
            'report_job',
            tags: {type: @job.task_type},
            values: {id: @job.id, status: 'line_flushed', line: index},
          )

          index += 1
        end
      end
    end
  end
end
