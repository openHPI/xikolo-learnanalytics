# frozen_string_literal: true

module Reports
  class EnrollmentStatisticsReport < Base
    def initialize(job)
      super

      @window_unit = extract_window_unit(job)
      @window_size = extract_window_size(job)

      @first_date = extract_date(job, 'first_day', 'first_month', 'first_year')
      @last_date = extract_date(job, 'last_day', 'last_month', 'last_year')

      @sliding_window = job.options['sliding_window']
      @include_active_users = job.options['include_active_users']
      @include_all_classifiers = job.options['include_all_classifiers']
    end

    def generate!
      @job.update(annotation: @job.task_scope)

      @reports_count = 1
      @report_index = 0

      # We have to fetch these already at this point for cluster grouping and
      # progress calculation.
      if @include_all_classifiers
        @classifiers = []

        classifiers_promise = Xikolo.paginate_with_retries(
          max_retries: 3, wait: 60.seconds,
        ) { course_service.rel(:classifiers).get }

        classifiers_promise.each_item do |classifier|
          # filter classifiers only if explicitly configured
          if reportable_classifiers.nil? ||
             reportable_classifiers.include?(classifier['cluster'])
            @classifiers.append(classifier)
          end
        end

        clusters = @classifiers.map {|c| c['cluster'] }.uniq
        @reports_count += clusters.size
      end

      csv_file(
        "EnrollmentStatisticsReport_#{@job.task_scope}_overall",
        headers,
        &each_timeframe
      )

      return unless @include_all_classifiers

      clusters.each do |cluster|
        @report_index += 1
        csv_file(
          "EnrollmentStatisticsReport_#{@job.task_scope}_" \
            "#{cluster.underscore.gsub(/[^0-9A-Z]/i, '_')}",
          headers(cluster),
          &each_timeframe(cluster)
        )
      end
    end

    private

    def extract_window_unit(job)
      window_unit = job.options['window_unit']

      unless %w[days months].include? window_unit
        raise InvalidReportArgumentError.new('window_unit', window_unit)
      end

      window_unit
    end

    def extract_window_size(job)
      window_size = job.options['window_size'].to_i

      unless window_size.positive?
        raise InvalidReportArgumentError.new('window_size', window_size)
      end

      window_size
    end

    def extract_date(job, day_name, month_name, year_name)
      window_unit = extract_window_unit(job)

      # Only the first day per month as the beginning of a time
      # window, if the time window spans full months.
      day = window_unit == 'months' ? 1 : job.options[day_name].to_i
      month = job.options[month_name].to_i
      year = job.options[year_name].to_i

      begin
        Date.parse("#{day}/#{month}/#{year}", '%d/%m/%Y')
      rescue Date::Error
        if window_unit == 'months'
          raise InvalidReportArgumentError.new(
            "#{month_name}/#{year_name}",
            "#{month}/#{year}",
          )
        else
          raise InvalidReportArgumentError.new(
            "#{day_name}/#{month_name}/#{year_name}",
            "#{day}/#{month}/#{year}",
          )
        end
      end
    end

    def timeframe_duration
      case @window_unit
        when 'days'
          @window_size.days
        when 'months'
          @window_size.months
      end
    end

    def dates
      @dates ||=
        begin
          all_dates =
            case @window_unit
              when 'days'
                (@first_date..@last_date).to_a
              when 'months'
                # Only the first day per month as the beginning of a time
                # window, if the time window spans full months.
                (@first_date..@last_date).to_a.select {|date| date.mday == 1 }
            end

          if @sliding_window || @window_size == 1
            # If the time window size is 1, or the window is sliding, all dates
            # are start dates.
            all_dates
          else
            # Omit the start dates that are within and not at the beginning of a
            # time window.
            all_dates.select.with_index do |_, index|
              index % @window_size == 0
            end
          end
        end
    end

    def headers(cluster = nil)
      headers = [
        'Start Date',
        'End Date',
      ]

      if cluster
        cc = classifier_for_cluster(cluster)
        cc.each do |c|
          headers += [
            "#{c['title']} - Total Enrollments",
            "#{c['title']} - Unique Enrolled Users",
          ]

          headers += ["#{c['title']} - Active Users"] if @include_active_users
        end
      else
        headers += [
          'Total Enrollments',
          'Unique Enrolled Users',
        ]

        headers += ['Active Users'] if @include_active_users
      end

      headers
    end

    # rubocop:disable Metrics/BlockLength
    def each_timeframe(cluster = nil)
      proc do |&block|
        timeframe_index = 0
        timeframe_count = dates.size

        unless @sliding_window
          timeframe_count = (timeframe_count / @window_size.to_f).ceil
        end

        dates.each do |date|
          first_date = date.to_s
          last_date = (date + timeframe_duration).to_s

          values = [
            first_date,
            last_date,
          ]

          if cluster
            cc = classifier_for_cluster(cluster)
            cc.each do |c|
              values += fetch_data(
                first_date,
                last_date,
                c['id'],
              )
            end
          else
            values += fetch_data(first_date, last_date)
          end

          block.call values

          timeframe_index += 1
          @job.progress_to(
            (@report_index * timeframe_count) + timeframe_index,
            of: @reports_count * timeframe_count,
          )
        end
      end
    end
    # rubocop:enable all

    def fetch_data(start_date, end_date, c_id = nil)
      stats, * = Xikolo::RetryingPromise.new(
        Xikolo::Retryable.new(max_retries: 3, wait: 20.seconds) do
          course_service.rel(:enrollment_stats).get(
            start_date: start_date,
            end_date: end_date,
            classifier_id: c_id,
          )
        end,
      ).value!

      values = [
        stats['total_enrollments'],
        stats['unique_enrolled_users'],
      ]

      if @include_active_users
        result = Lanalytics::Metric::ActiveUserCount.query(
          start_date: start_date,
          end_date: end_date,
          resource_id: c_id,
        )

        values += [result[:active_users]]
      end
      values
    end

    def classifier_for_cluster(cluster)
      @classifiers
        .select {|c| c['cluster'] == cluster }
        .sort_by {|c| c['title'].downcase }
    end

    def reportable_classifiers
      Lanalytics.config.reports['classifiers'] || []
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end
  end
end
