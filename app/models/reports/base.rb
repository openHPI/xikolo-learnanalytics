require 'csv'

module Reports
  class Base
    def initialize(job, _options = {})
      # Subclasses can override this method if they need access to the additional options
      @job = job
    end

    def files
      @files ||= []
    end

    private

    def csv_file(target, headers, &block)
      target = "#{target}_#{DateTime.now.strftime('%Y-%m-%d')}.csv"
      files << target

      CSV.open(target, 'wb') do |csv|
        csv << headers

        block.call do |row|
          csv << row
          csv.flush
        end
      end
    end
  end
end
