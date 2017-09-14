module Reports
  class EnrollmentReport < Base

    def initialize(job, options = {})
      super

      @start_month = options['start_month'].to_i
      @start_year = options['start_year'].to_i
      @end_month = options['end_month'].to_i
      @end_year = options['end_year'].to_i

      @sliding_window_in_months = options['sliding_window_in_months'].to_i

      @include_active_users = options['include_active_users']
      @include_all_classifiers = options['include_all_classifiers']
    end

    def generate!
      @job.update(annotation: @job.task_scope)

      @reports_count = 1
      @report_index = 0

      # we have to fetch these already for progress calculation
      if @include_all_classifiers
        classifiers = course_service.rel(:classifiers).get.value!
        @reports_count += classifiers.size
      end

      csv_file 'EnrollmentReport_global', headers, &each_timeframe

      if @include_all_classifiers
        classifiers.each do |classifier|
          @report_index += 1
          csv_file "EnrollmentReport_#{classifier['title'].underscore.gsub(/[^0-9A-Z]/i, '_')}", headers, &each_timeframe(classifier[:id])
        end
      end
    end

    private

    def headers
      headers = [
        'Start Date',
        'End Date',
        'Total Enrollments',
        'Unique Enrolled Users'
      ]

      if @include_active_users
        headers += ['Active Users']
      end

      headers
    end

    def each_timeframe(classifier_id = nil)
      Proc.new do |&block|
        start_date = Date.new(@start_year, @start_month, 1)
        end_date = Date.new(@end_year, @end_month, 1)
        timeframe_count = (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month) + 1
        timeframe_index = 0

        (@start_year..@end_year).each do |year|
          (1..12).each do |month|
            next if (year == @start_year && month < @start_month) || (year == @end_year && month > @end_month)

            current_start_date = Date.new(year, month, 1).to_s
            current_end_date = (Date.new(year, month, 1) + @sliding_window_in_months.month).to_s

            stats = course_service.rel(:enrollment_stats).get(
              start_date: current_start_date,
              end_date: current_end_date,
              classifier_id: classifier_id
            ).value!

            values = [
              current_start_date,
              current_end_date,
              stats[:total_enrollments],
              stats[:unique_enrolled_users]
            ]

            if @include_active_users
              active_users = Lanalytics::Metric::ActiveUserCount.query(
                nil,
                nil,
                current_start_date,
                current_end_date,
                classifier_id,
                nil,
                nil
              )

              values += [active_users]
            end

            block.call values

            timeframe_index += 1
            @job.progress_to((@report_index * timeframe_count) + timeframe_index, of: @reports_count * timeframe_count)
          end
        end
      end
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end

  end
end
