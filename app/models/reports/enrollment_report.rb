module Reports
  class EnrollmentReport < Base

    def initialize(job)
      super

      @start_month = job.options['start_month'].to_i
      @start_year = job.options['start_year'].to_i
      @end_month = job.options['end_month'].to_i
      @end_year = job.options['end_year'].to_i

      @window_in_months = [job.options['window_in_months'].to_i, 1].max
      @sliding_window = job.options['sliding_window']

      @include_active_users = job.options['include_active_users']
      @include_all_classifiers = job.options['include_all_classifiers']
    end

    def generate!
      @job.update(annotation: @job.task_scope)

      @reports_count = 1
      @report_index = 0

      # we have to fetch these already for cluster grouping and progress calculation
      if @include_all_classifiers
        @classifiers = []
        Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
          course_service.rel(:classifiers).get
        end.each_item do |classifier|
          # filter classifiers only if explicitly configured
          if reportable_classifiers.nil? ||
             reportable_classifiers.include?(classifier['cluster'])
            @classifiers.append(classifier)
          end
        end
        clusters = @classifiers.map { |c| c['cluster'] }.uniq
        @reports_count += clusters.size
      end

      csv_file "EnrollmentReport_#{@job.task_scope}_global", headers, &each_timeframe

      if @include_all_classifiers
        clusters.each do |cluster|
          @report_index += 1
          csv_file "EnrollmentReport_#{@job.task_scope}_#{cluster.underscore.gsub(/[^0-9A-Z]/i, '_')}", headers(cluster), &each_timeframe(cluster)
        end
      end
    end

    private

    def classifier_for_cluster(cluster)
      @classifiers.select { |c| c['cluster'] == cluster }.sort_by { |c| c['title'].downcase }
    end

    def reportable_classifiers
      Lanalytics.config.reports['classifiers'] || []
    end

    def headers(cluster = nil)
      headers = [
        'Start Date',
        'End Date'
      ]

      if cluster
        cc = classifier_for_cluster(cluster)
        cc.each do |c|
          headers += [
            "#{c['title']} - Total Enrollments",
            "#{c['title']} - Unique Enrolled Users"
          ]
          if @include_active_users
            headers += ["#{c['title']} - Active Users"]
          end
        end
      else
        headers += [
          'Total Enrollments',
          'Unique Enrolled Users'
        ]
        if @include_active_users
          headers += ['Active Users']
        end
      end

      headers
    end

    def each_timeframe(cluster = nil)
      Proc.new do |&block|
        start_date = Date.new(@start_year, @start_month, 1)
        end_date = Date.new(@end_year, @end_month, 1)

        timeframe_count = (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month) + 1

        unless @sliding_window
          timeframe_count = (timeframe_count / @window_in_months.to_f).ceil
        end

        timeframe_index = 0
        fixed_interval_index = -1

        (@start_year..@end_year).each do |year|
          (1..12).each do |month|
            next if (year == @start_year && month < @start_month) || (year == @end_year && month > @end_month)

            fixed_interval_index += 1

            unless @sliding_window
              next if fixed_interval_index % @window_in_months != 0
            end

            current_start_date = Date.new(year, month, 1).to_s
            current_end_date = (Date.new(year, month, 1) + @window_in_months.month).to_s

            values = [
              current_start_date,
              current_end_date
            ]

            if cluster
              cc = classifier_for_cluster(cluster)
              cc.each do |c|
                values += fetch_data(current_start_date, current_end_date, c['id'])
              end
            else
              values += fetch_data(current_start_date, current_end_date)
            end

            block.call values

            timeframe_index += 1
            @job.progress_to((@report_index * timeframe_count) + timeframe_index, of: @reports_count * timeframe_count)
          end
        end
      end
    end

    def fetch_data(start_date, end_date, c_id = nil)
      stats, * = Xikolo::RetryingPromise.new(
        Xikolo::Retryable.new(max_retries: 3, wait: 20.seconds) {
          course_service.rel(:enrollment_stats).get(
            start_date: start_date,
            end_date: end_date,
            classifier_id: c_id
          )
        }
      ).value!

      values = [
        stats['total_enrollments'],
        stats['unique_enrolled_users']
      ]

      if @include_active_users
        result = Lanalytics::Metric::ActiveUserCount.query(
          start_date: start_date,
          end_date: end_date,
          resource_id: c_id
        )

        values += [result[:active_users]]
      end
      values
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end

  end
end
