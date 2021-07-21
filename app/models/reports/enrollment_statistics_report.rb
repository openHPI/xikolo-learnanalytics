# frozen_string_literal: true

module Reports
  class EnrollmentStatisticsReport < Base
    class << self
      def form_data
        {
          type: :enrollment_statistics_report,
          name: I18n.t(:'reports.enrollment_statistics_report.name'),
          description: I18n.t(:'reports.enrollment_statistics_report.desc'),
          options: [
            {
              type: 'checkbox',
              name: :machine_headers,
              label: I18n.t(:'reports.shared_options.machine_headers'),
            },
            {
              type: 'date_field',
              name: :first_date,
              options: {
                min: '2013-01-01',
                required: true,
              },
              label: I18n.t(:'reports.enrollment_statistics_report.options.first_date'),
            },
            {
              type: 'date_field',
              name: :last_date,
              options: {
                min: '2013-01-01',
                required: true,
              },
              label: I18n.t(:'reports.enrollment_statistics_report.options.last_date'),
            },
            {
              type: 'radio_group',
              name: :window_unit,
              values: {
                days: I18n.t(:'reports.enrollment_statistics_report.options.window_unit_days'),
                months: I18n.t(:'reports.enrollment_statistics_report.options.window_unit_months'),
              },
              label: I18n.t(:'reports.enrollment_statistics_report.options.window_unit'),
            },
            {
              type: 'number_field',
              name: :window_size,
              options: {
                value: 1,
                min: 1,
                input_size: 'extra-small',
              },
              label: I18n.t(:'reports.enrollment_statistics_report.options.window_size'),
            },
            {
              type: 'checkbox',
              name: :sliding_window,
              label: I18n.t(:'reports.enrollment_statistics_report.options.sliding_window'),
            },
            {
              type: 'checkbox',
              name: :include_all_classifiers,
              label: I18n.t(:'reports.enrollment_statistics_report.options.all_classifiers'),
            },
            {
              type: 'checkbox',
              name: :include_active_users,
              label: I18n.t(:'reports.enrollment_statistics_report.options.active_users'),
            },
            {
              type: 'text_field',
              name: :zip_password,
              label: I18n.t(:'reports.shared_options.zip_password'),
              options: {
                placeholder: I18n.t(:'reports.shared_options.zip_password_placeholder'),
                input_size: 'large',
              },
            },
          ],
        }
      end
    end

    def initialize(job)
      super

      @window_unit = extract_window_unit(job)
      @window_size = extract_window_size(job)

      @first_date = extract_date(job, 'first')
      @last_date = extract_date(job, 'last')

      @sliding_window = job.options['sliding_window']
      @include_active_users = job.options['include_active_users']
      @include_all_classifiers = job.options['include_all_classifiers']
    end

    def generate!
      @job.update(annotation: annotation)

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
        "EnrollmentStatisticsReport_#{annotation}_overall",
        headers,
        &each_timeframe
      )

      return unless @include_all_classifiers

      clusters.each do |cluster|
        @report_index += 1
        csv_file(
          "EnrollmentStatisticsReport_#{annotation}_#{cluster.underscore.gsub(/[^0-9A-Z]/i, '_')}",
          headers(cluster),
          &each_timeframe(cluster)
        )
      end
    end

    private

    def annotation
      @annotation ||= begin
        date_format = if @window_unit == 'months'
                        '%m_%Y'
                      else
                        '%d_%m_%Y'
                      end

        "#{@first_date.strftime(date_format)}_#{@last_date.strftime(date_format)}_#{@window_size}_#{@window_unit}"
      end
    end

    def extract_window_unit(job)
      window_unit = job.options['window_unit']

      raise InvalidReportArgumentError.new('window_unit', window_unit) unless %w[days months].include? window_unit

      window_unit
    end

    def extract_window_size(job)
      window_size = job.options['window_size'].to_i

      raise InvalidReportArgumentError.new('window_size', window_size) unless window_size.positive?

      window_size
    end

    def extract_date(job, prefix)
      window_unit = extract_window_unit(job)

      begin
        date = Date.parse(job.options["#{prefix}_date"], '%Y-%m-%d')

        return date if window_unit != 'months'

        # Only the first day per month as the beginning of a time
        # window, if the time window spans full months.
        date.change(day: 1)
      rescue Date::Error
        raise InvalidReportArgumentError.new(
          "#{prefix}_date",
          job.options["#{prefix}_date"],
        )
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

    # rubocop:disable Metrics/CyclomaticComplexity
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
    # rubocop:enable all

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

    def each_timeframe(cluster = nil)
      proc do |&block|
        timeframe_index = 0
        timeframe_count = dates.size

        timeframe_count = (timeframe_count / @window_size.to_f).ceil unless @sliding_window

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
      @course_service ||= Restify.new(:course).get.value!
    end
  end
end
