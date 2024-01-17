# frozen_string_literal: true

module Reports
  class CourseReport < Base
    queue_as :reports_long_running

    class << self
      def form_data
        {
          type: :course_report,
          name: I18n.t(:'reports.course_report.name'),
          description: I18n.t(:'reports.course_report.desc'),
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
              name: :include_access_groups,
              label: I18n.t(:'reports.shared_options.access_groups'),
            },
            {
              type: 'checkbox',
              name: :include_profile,
              label: I18n.t(:'reports.shared_options.profile'),
            },
            {
              type: 'checkbox',
              name: :include_auth,
              label: I18n.t(:'reports.shared_options.auth'),
            },
            {
              type: 'checkbox',
              name: :include_analytics_metrics,
              label: I18n.t(:'reports.shared_options.analytics_metrics'),
            },
            {
              type: 'checkbox',
              name: :include_all_quizzes,
              label: I18n.t(:'reports.course_report.options.all_quizzes'),
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

      @de_pseudonymized = job.options['de_pseudonymized']
      @include_analytics_metrics = job.options['include_analytics_metrics']
      @include_access_groups = job.options['include_access_groups']
      @include_profile = job.options['include_profile']
      @include_auth = job.options['include_auth']
      @include_sections = true
      @include_all_quizzes = job.options['include_all_quizzes']
    end

    def generate!
      @job.update(annotation: course['course_code'])

      csv_file("CourseReport_#{course['course_code']}", headers) do |&write|
        each_row(&write)
      end
    end

    private

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def each_row(&)
      # Initialize access groups to preload some data.
      access_groups if @include_access_groups

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
        row_for_course(course, &)
      end
    end

    def row_for_course(course)
      enrollments_counter = 0

      # these metrics are fetched for all users at once from postgres
      # needs more memory but much faster performance
      if @include_analytics_metrics
        clustering_metrics = fetch_clustering_metrics(course)

        video_count ||= Xikolo::RetryingPromise.new(
          Xikolo::Retryable.new(max_retries: 3, wait: 60.seconds) do
            course_service.rel(:items).get(
              course_id: course['id'],
              content_type: 'video',
              was_available: true,
            )
          end,
        ).value!.first.count

        start_date = Date.parse(course['start_date'])
        end_date = if course['end_date'].present?
                     Date.parse(course['end_date'])
                   else
                     Time.zone.today
                   end
        course_days = (end_date - start_date).to_i
      end

      enrollments_promise = Xikolo.paginate_with_retries(
        max_retries: 3, wait: 60.seconds,
      ) do
        course_service.rel(:enrollments).get(
          course_id: course['id'], per_page: 1000, deleted: true,
        )
      end

      enrollments_promise.each_item do |e, enrollment_page|
        user = Xikolo::RetryingPromise.new(
          Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
            account_service.rel(:user).get(id: e['user_id'])
          end,
        ).value!.first

        Xikolo::RetryingPromise.new(
          Xikolo::Retryable.new(max_retries: 3, wait: 60.seconds) do
            course_service.rel(:enrollments).get(
              course_id: course['id'],
              user_id: e['user_id'],
              deleted: true,
              learning_evaluation: true,
            )
          end,
          Xikolo::Retryable.new(max_retries: 3, wait: 20.seconds) do
            pinboard_service.rel(:statistic).get(
              id: course['id'],
              user_id: user['id'],
            )
          end,
        ) do |enrollments, stat_pinboard|
          enrollment = enrollments.first
          course_start_date = as_date(course['start_date'])
          birth_compare_date = course_start_date || DateTime.now
          enrollment_date = as_date(enrollment['created_at'])

          age_data = BirthDate.new(user['born_at'])
          age_group = age_data.age_group_at(birth_compare_date)

          user_id = if @de_pseudonymized
                      user['id']
                    else
                      Digest::SHA256.hexdigest(user['id'])
                    end

          values = [
            user_id,
            enrollment_date,
            first_enrollment?(enrollment),
            user['created_at'],
            user['language'],
            age_group,
          ]

          if @de_pseudonymized
            values += [
              escape_csv_string(user['full_name']),
              user['email'],
              user['born_at'],
            ]
          end

          if @include_access_groups
            memberships = access_groups.memberships_for(user)
            values.append(escape_csv_string(memberships.join('; ')))
          end

          if @include_profile
            values += [user['avatar_url'].present? ? 'true' : '']

            profile = Xikolo::RetryingPromise.new(
              Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
                user.rel(:profile).get
              end,
            ).value!.first
            values += profile_config.for(profile).values
          end

          values.concat(auth_fields.values(user['id'])) if @include_auth && @de_pseudonymized

          # get elasticsearch / postgres metrics per user
          if @include_analytics_metrics
            user_course_country = fetch_metric(
              'UserCourseCountry', course['id'], user['id']
            ) || ''
            user_course_city = fetch_metric(
              'UserCourseCity', course['id'], user['id']
            ) || ''
            device_usage = fetch_device_usage(
              course['id'], user['id']
            )
            first_action = fetch_metric(
              'FirstAction', course['id'], user['id']
            )
            first_visited_item = fetch_metric(
              'FirstVisitedItem', course['id'], user['id']
            )
            last_action = fetch_metric(
              'LastAction', course['id'], user['id']
            )
            last_visited_item = fetch_metric(
              'LastVisitedItem', course['id'], user['id']
            )
            forum_activity = fetch_metric(
              'ForumActivity', course['id'], user['id']
            )&.dig(:total)
            forum_write_activity = fetch_metric(
              'ForumWriteActivity', course['id'], user['id']
            )&.dig(:total)

            values += [
              user_course_country,
              suppress(IsoCountryCodes::UnknownCodeError) do
                IsoCountryCodes.find(user_course_country)&.name
              end,
              user_course_city,
              device_usage['desktop web'],
              device_usage['mobile web'],
              device_usage['mobile app'],
              first_action&.dig('timestamp') || '',
              first_visited_item&.dig('timestamp') || '',
              last_action&.dig('timestamp') || '',
              last_visited_item&.dig('timestamp') || '',
              last_visited_item&.dig(
                'resource', 'resource_uuid'
              ) || '',
              clustering_metrics.dig(
                user['id'], 'sessions'
              ) || '',
              clustering_metrics.dig(
                user['id'], 'average_session_duration'
              ) || '',
              clustering_metrics.dig(
                user['id'], 'total_session_duration'
              ) || '',
              clustering_metrics.dig(
                user['id'], 'unique_video_play_activity'
              ) || '',
              percentage(
                clustering_metrics.dig(
                  user['id'], 'unique_video_play_activity'
                ),
                of: video_count,
              ) || '',
              clustering_metrics.dig(
                user['id'], 'unique_video_downloads_activity'
              ) || '',
              percentage(
                clustering_metrics.dig(
                  user['id'], 'unique_video_downloads_activity'
                ),
                of: video_count,
              ) || '',
              clustering_metrics.dig(
                user['id'], 'unique_slide_downloads_activity'
              ) || '',
              percentage(
                clustering_metrics.dig(
                  user['id'], 'unique_slide_downloads_activity'
                ),
                of: video_count,
              ) || '',
              forum_activity,
              forum_activity.to_f / course_days,
              forum_write_activity,
              clustering_metrics.dig(
                user['id'], 'quiz_performance'
              ) || '',
              clustering_metrics.dig(
                user['id'], 'graded_quiz_performance'
              ) || '',
              clustering_metrics.dig(
                user['id'], 'ungraded_quiz_performance'
              ) || '',
            ]
          end

          # Try to calculate enrollment delta
          values << if course_start_date && enrollment_date
                      (enrollment_date - course_start_date).to_i
                    else
                      ''
                    end

          top_performance = if enrollment['quantile'].present?
                              calculate_top_performance(
                                enrollment['quantile'],
                              )
                            else
                              ''
                            end

          values += [
            stat_pinboard['posts'],
            stat_pinboard['threads'],
            enrollment['forced_submission_date'].present? || '',
            enrollment['forced_submission_date'] || '',
            enrollment.dig(
              'certificates', 'confirmation_of_participation'
            ) || '',
            enrollment.dig('certificates', 'record_of_achievement') || '',
            enrollment.dig('certificates', 'certificate') || '',
            enrollment['completed'] || '',
            enrollment['deleted'] || '',
            enrollment['quantile'] || '',
            top_performance,
            enrollment.dig('visits', 'visited'),
            enrollment.dig('visits', 'percentage'),
            enrollment.dig('points', 'achieved'),
            enrollment.dig('points', 'percentage'),
          ]

          # For each section, append visit percentage and points percentage
          if @include_sections
            progresses = Xikolo::RetryingPromise.new(
              Xikolo::Retryable.new(max_retries: 3, wait: 60.seconds) do
                course_service.rel(:progresses).get(
                  user_id: user['id'],
                  course_id: course['id'],
                )
              end,
            ).value!.first

            values += course_sections.map do |s|
              p = progresses.find {|pr| pr['resource_id'] == s['id'] }

              next unless p

              total = p.dig('visits', 'total').to_f
              n = p.dig('visits', 'user').to_f
              percentage n, of: total
            end

            values += course_sections.map do |s|
              p = progresses.find {|pr| pr['resource_id'] == s['id'] }

              next unless p

              total = p.dig('selftest_exercises', 'max_points').to_f
              n = p.dig('selftest_exercises', 'graded_points').to_f
              percentage n, of: total
            end

            values += course_sections.map do |s|
              p = progresses.find {|pr| pr['resource_id'] == s['id'] }

              next unless p

              total = p.dig('main_exercises', 'max_points').to_f
              n = p.dig('main_exercises', 'graded_points').to_f
              percentage n, of: total
            end

            values += course_sections.map do |s|
              p = progresses.find {|pr| pr['resource_id'] == s['id'] }

              next unless p

              total = p.dig('bonus_exercises', 'max_points').to_f
              n = p.dig('bonus_exercises', 'graded_points').to_f
              percentage n, of: total
            end
          end

          all_submissions = all_user_submissions(user['id'])
          values += quizzes.map do |q|
            s = all_submissions[q['content_id']]

            next unless s

            total = q['max_points'].to_f
            n = s['points'].to_f + s['fudge_points'].to_f
            percentage n, of: total
          end

          values += [course['course_code']]

          yield values

          # Update report progress
          enrollments_counter += 1
          progress.update(
            course['id'],
            enrollments_counter,
            max: enrollment_page.response.headers['X_TOTAL_COUNT'].to_i,
          )
        end.value!
      end
    end
    # rubocop:enable all

    def fetch_device_usage(course_id, user_id)
      device_usage = fetch_metric('DeviceUsage', course_id, user_id)

      result = {}

      device_usage[:behavior][:usage].each do |usage|
        result[usage[:category]] = usage[:total_activity].to_s
      end

      result
    end

    def fetch_metric(metric, course_id, user_id)
      metric = "Lanalytics::Metric::#{metric}".constantize
      metric.query(user_id:, course_id:)
    end

    def fetch_clustering_metrics(course)
      return {} unless @include_analytics_metrics

      clustering_metrics = %w[
        sessions
        average_session_duration
        total_session_duration
        unique_video_play_activity
        unique_video_downloads_activity
        unique_slide_downloads_activity
        quiz_performance
        graded_quiz_performance
        ungraded_quiz_performance
      ]
      result = Lanalytics::Clustering::Dimensions.query(
        course['id'], clustering_metrics, nil
      )
      result.to_h {|x| [x['user_uuid'], x.except('user_uuid')] }
    end

    def calculate_top_performance(quantile)
      return '' unless quantile

      top_percentage = (1 - quantile.to_f).round(10)
      if top_percentage <= 0.05
        'Top5'
      elsif top_percentage <= 0.1
        'Top10'
      elsif top_percentage <= 0.2
        'Top20'
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def headers
      @headers ||= [
        @de_pseudonymized ? 'User ID' : 'User Pseudo ID',
        'Enrollment Date',
        'First Enrollment',
        'User created',
        'Language',
        'Age Group',
      ].tap do |headers|
        if @de_pseudonymized
          headers.push(
            'Full Name',
            'Email',
            'Birth Date',
          )
        end

        headers.append('Access Groups') if @include_access_groups

        if @include_profile
          headers.push 'Profile Picture'
          headers.concat profile_config.all_titles
        end

        headers.concat(auth_fields.headers) if @include_auth && @de_pseudonymized

        if @include_analytics_metrics
          headers.push(
            'Top Country (Code)',
            'Top Country (Name)',
            'Top City',
            'Desktop Web Activity',
            'Mobile Web Activity',
            'Mobile App Activity',
            'First Action Timestamp',
            'First Visited Item Timestamp',
            'Last Action Timestamp',
            'Last Visited Item Timestamp',
            'Last Visited Item',
            'Sessions',
            'Avg. Session Duration',
            'Total Session Duration',
            'Video Play Activity',
            'Video Play Activity (Percentage)',
            'Video Downloads Activity',
            'Video Downloads Activity (Percentage)',
            'Slide Downloads Activity',
            'Slide Downloads Activity (Percentage)',
            'Forum Activity',
            'Forum Activity per Day',
            'Forum Posting Activity',
            'Quiz Performance',
            'Graded Quiz Performance',
            'Ungraded Quiz Performance',
          )
        end

        headers.push(
          'Enrollment Delta in Days',
          'Forum Posts',
          'Forum Threads',
          'Reactivated',
          'Reactivated Submission Date',
          'Confirmation of Participation',
          'Record of Achievement',
          'Qualified Certificate',
          'Course Completed',
          'Un-enrolled',
          'Quantile',
          'Top Performance',
          'Items Visited',
          'Items Visited Percentage',
          'Points',
          'Points Percentage',
        )

        if @include_sections
          headers.concat(
            course_sections.map do |s|
              "#{s['title'].titleize} Visited Percentage (Section)"
            end,
          )
          headers.concat(
            course_sections.map do |s|
              "#{s['title'].titleize} Self-tests Percentage (Section)"
            end,
          )
          headers.concat(
            course_sections.map do |s|
              "#{s['title'].titleize} Assignments Percentage (Section)"
            end,
          )
          headers.concat(
            course_sections.map do |s|
              "#{s['title'].titleize} Bonus Percentage (Section)"
            end,
          )
        end

        headers.concat quiz_column_headers

        headers.push 'Course Code'
      end
    end
    # rubocop:enable all

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

    def course_sections
      @course_sections ||= Xikolo::RetryingPromise.new(
        Xikolo::Retryable.new(max_retries: 3, wait: 60.seconds) do
          course_service.rel(:sections).get(
            course_id: course['id'],
            published: true,
            include_alternatives: true,
          )
        end,
      ).value!.first
    end

    def quiz_column_headers
      quizzes.map do |q|
        section = course_sections.find do |s|
          s['id'] == q['section_id']
        end || {'title' => ''}

        "#{section['title'].titleize} - #{q['title'].titleize} Percentage (Quiz)"
      end
    end

    def profile_config
      @profile_config ||= if @de_pseudonymized
                            ProfileFieldConfiguration.de_pseudonymized
                          else
                            ProfileFieldConfiguration.pseudonymized
                          end
    end

    def quizzes
      return [] unless @include_all_quizzes

      if @quizzes.nil?
        @quizzes = []

        items_promise = Xikolo.paginate_with_retries(
          max_retries: 3, wait: 60.seconds,
        ) do
          course_service.rel(:items).get(
            course_id: course['id'],
            content_type: 'quiz',
          )
        end

        items_promise.each_item do |quiz|
          @quizzes.append(quiz) if %w[main selftest bonus].include? quiz['exercise_type']
        end
      end

      @quizzes
    end

    def all_user_submissions(user_id)
      return {} unless @include_all_quizzes

      all_submissions = []

      submissions_promise = Xikolo.paginate_with_retries(
        max_retries: 3,
        wait: 60.seconds,
      ) do
        quiz_service.rel(:quiz_submissions).get(
          user_id:,
          only_submitted: true,
          course_id: course['id'],
        )
      end

      submissions_promise.each_item do |submissions|
        all_submissions.append(submissions)
      end

      # Get last submission for every quiz
      all_submissions
        .group_by {|submission| submission['quiz_id'] }
        .to_h do |quiz_id, arr|
          last_submission = arr.max_by do |s|
            DateTime.parse(s['quiz_submission_time'])
          end

          [quiz_id, last_submission]
        end
    end

    def first_enrollment?(enrollment)
      all_enrollments = []

      enrollments_promise = Xikolo.paginate_with_retries(
        max_retries: 3,
        wait: 60.seconds,
      ) do
        course_service.rel(:enrollments).get(
          user_id: enrollment['user_id'],
          deleted: true,
          per_page: 500,
        )
      end

      enrollments_promise.each_item do |enrollments|
        all_enrollments.append(enrollments)
      end

      compare_date = as_date(enrollment['created_at'])

      return '' unless compare_date

      all_enrollments
        .filter_map {|e| as_date(e['created_at']) }
        .none? {|date| date < compare_date }
    end

    # rubocop:disable Style/FloatDivision
    def percentage(number, of:)
      return if number.blank? || of.to_f.zero?

      # Cast `number` and `of` to floats since they can be strings
      format('%.4f', number.to_f / of.to_f)
    end
    # rubocop:enable all

    def account_service
      @account_service ||= Restify.new(:account).get.value!
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end

    def pinboard_service
      @pinboard_service ||= Restify.new(:pinboard).get.value!
    end

    def quiz_service
      @quiz_service ||= Restify.new(:quiz).get.value!
    end

    def as_date(string_or_nil)
      string_or_nil && DateTime.parse(string_or_nil)
    end

    def access_groups
      @access_groups ||= AccessGroups.new
    end

    def auth_fields
      @auth_fields ||= AuthFields.new
    end
  end
end
