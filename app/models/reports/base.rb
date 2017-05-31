require 'csv'

module Reports
  class Base
    def initialize(job, _params = {})
      # Subclasses can override this method if they need access to the additional parameters
      @job = job
    end

    def files
      @files ||= []
    end

    private

    def csv_file(target, headers, &block)
      file = @job.tmp_directory.join("#{target}_#{DateTime.now.strftime('%Y-%m-%d')}.csv")
      files << file

      CSV.open(File.absolute_path(file), 'wb') do |csv|
        csv << headers

        block.call do |row|
          csv << row
          csv.flush
        end
      end
    end
  end
end
