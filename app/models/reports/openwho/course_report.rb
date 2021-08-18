# frozen_string_literal: true

module Reports::Openwho
  class CourseReport < Reports::Base
    queue_as :reports_long_running

    class << self
      def form_data
        {
          type: :openwho_course_report,
          name: I18n.t(:'reports.openwho_course_report.name'),
          description: I18n.t(:'reports.openwho_course_report.desc'),
          scope: {
            type: 'select',
            name: :task_scope,
            label: I18n.t(:'reports.shared_options.select_course'),
            values: :courses,
            options: {
              prompt: I18n.t(:'reports.shared_options.select_blank'),
              disabled: '', # disable prompt option (rails 6)
              required: true,
            },
          },
          options: [
            {
              type: 'checkbox',
              name: :machine_headers,
              label: I18n.t(:'reports.shared_options.machine_headers'),
            },
            {
              type: 'checkbox',
              name: :de_pseudonymized,
              label: I18n.t(:'reports.shared_options.de_pseudonymized'),
            },
            {
              type: 'checkbox',
              name: :include_enrollment_evaluation,
              label: I18n.t(:'reports.shared_options.enrollment_evaluation'),
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

      @de_pseudonymized =
        job.options['de_pseudonymized']
      @include_enrollment_evaluation =
        job.options['include_enrollment_evaluation']
    end

    def generate!
      @job.update(annotation: course['course_code'])

      csv_file("OpenWHO_CourseReport_#{course['course_code']}", headers) do |&write|
        each_row(&write)
      end
    end

    private

    def headers
      @headers ||= [
        @de_pseudonymized ? 'User ID' : 'User Pseudo ID',
        'User Created',
        'Enrollment Date',
        'User Language',
        'Affiliated',
        'Age Group',
        'Primary Language (Profile)',
        'Gender (Profile)',
        'Affiliation (Profile)',
        'Country of Nationality (Profile)',
        'Last Country (Name)',
      ].tap do |headers|
        headers.append('Last Country (Region)') if reportable_country_regions.any?

        if @include_enrollment_evaluation
          headers.append(
            'Items Visited',
            'Items Visited Percentage',
            'Points',
            'Points Percentage',
          )
        end

        headers.append(
          'Course Code',
          'Course Language',
        )
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def each_row(&block)
      # Pre-warm progress counter with current maximum values. They might change
      # while processing but will give a good expectation for the actual target.
      # This will make progress basically linear.
      courses.each do |course|
        total_count = Xikolo::RetryingPromise.new(
          Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
            course_service
              .rel(:enrollments)
              .get(course_id: course['id'], per_page: 1, deleted: true)
          end,
        ).value!.first.response.headers['X_TOTAL_COUNT'].to_i

        progress.update(course['id'], 0, max: total_count)
      end

      courses.each do |course| # rubocop:disable Style/CombinableLoops
        row_for_course(course, &block)
      end
    end

    def row_for_course(course)
      enrollments_counter = 0

      enrollments_promise =
        Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
          course_service.rel(:enrollments).get(
            course_id: course['id'], per_page: 1000, deleted: true,
          )
        end

      enrollments_promise.each_item do |enrollment, enrollment_page|
        user = Xikolo::RetryingPromise.new(
          Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
            account_service.rel(:user).get(id: enrollment['user_id'])
          end,
        ).value!.first

        profile = Xikolo::RetryingPromise.new(
          Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
            user.rel(:profile).get
          end,
        ).value!.first

        course_start_date = course['start_date']&.to_datetime
        birth_compare_date = course_start_date || Time.zone.now
        age_data = BirthDate.new(user['born_at'])
        age_group = age_data.age_group_at(birth_compare_date)

        profile_fields = profile_config.for(profile)

        user_id = if @de_pseudonymized
                    user['id']
                  else
                    Digest::SHA256.hexdigest(user['id'])
                  end

        values = [
          user_id,
          user['created_at'],
          enrollment['created_at'],
          user['language'],
          user['affiliated'],
          age_group,
          profile_fields['primary_language'],
          profile_fields['gender'],
          profile_fields['affiliation'],
          profile_fields['country'],
        ]

        last_country_code = fetch_metric(
          'LastCountry', course['id'], user['id']
        )[:code]
        last_country_name = suppress(IsoCountryCodes::UnknownCodeError) do
          IsoCountryCodes.find(last_country_code)&.name
        end

        values.append(last_country_name || last_country_code)

        if reportable_country_regions.any?
          regions = reportable_country_regions.select do |_, countries|
            countries.any? {|c| c.casecmp(last_country_code) == 0 }
          end

          values.append(regions.keys.join(';'))
        end

        if @include_enrollment_evaluation
          evaluation = Xikolo::RetryingPromise.new(
            Xikolo::Retryable.new(max_retries: 3, wait: 60.seconds) do
              course_service.rel(:enrollments).get(
                course_id: course['id'],
                user_id: enrollment['user_id'],
                deleted: true,
                learning_evaluation: true,
              )
            end,
          ).value!.first.first # destruct promise array and then response

          values.append(
            evaluation.dig('visits', 'visited'),
            evaluation.dig('visits', 'percentage'),
            evaluation.dig('points', 'achieved'),
            evaluation.dig('points', 'percentage'),
          )
        end

        values.append(
          course['course_code'],
          course['lang'],
        )

        yield values

        # Update report progress
        enrollments_counter += 1
        progress.update(
          course['id'],
          enrollments_counter,
          max: enrollment_page.response.headers['X_TOTAL_COUNT'].to_i,
        )
      end
    end
    # rubocop:enable all

    def fetch_metric(metric, course_id, user_id)
      metric = "Lanalytics::Metric::#{metric}".constantize
      metric.query(user_id: user_id, course_id: course_id)
    end

    def reportable_country_regions
      Lanalytics.config.reports['country_regions'] || {}
    end

    def profile_config
      @profile_config ||= if @de_pseudonymized
                            ProfileFieldConfiguration.de_pseudonymized
                          else
                            ProfileFieldConfiguration.pseudonymized
                          end
    end

    def courses
      # return an array with the course
      @courses ||= Xikolo::RetryingPromise.new(
        Xikolo::Retryable.new(max_retries: 3, wait: 60.seconds) do
          course_service.rel(:course).get(id: @job.task_scope)
        end,
      ).value!
    end

    def course
      courses.first
    end

    def account_service
      @account_service ||= Restify.new(:account).get.value!
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end
  end
end
