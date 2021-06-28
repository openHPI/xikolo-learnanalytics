# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
module Reports
  class UserReport < Base
    queue_as :reports_long_running

    class << self
      def structure
        {
          type: :user_report,
          name: I18n.t(:'reports.user_report'),
          description: I18n.t(:'reports.user_report_explanation'),
          options: [
            {
              type: 'checkbox',
              name: :machine_headers,
              label: I18n.t(:'reports.machine_headers'),
            },
            {
              type: 'checkbox',
              name: :de_pseudonymized,
              label: I18n.t(:'reports.de_pseudonymized'),
            },
            {
              type: 'checkbox',
              name: :include_top_location,
              label: I18n.t(:'reports.include_top_location'),
            },
            {
              type: 'checkbox',
              name: :include_access_groups,
              label: I18n.t(:'reports.include_access_groups'),
            },
            {
              type: 'checkbox',
              name: :include_profile,
              label: I18n.t(:'reports.include_profile'),
            },
            {
              type: 'checkbox',
              name: :include_auth,
              label: I18n.t(:'reports.include_auth'),
            },
            {
              type: 'checkbox',
              name: :include_consents,
              label: I18n.t(:'reports.include_consents'),
            },
            {
              type: 'checkbox',
              name: :include_features,
              label: I18n.t(:'reports.include_features'),
            },
            {
              type: 'checkbox',
              name: :include_email_subscriptions,
              label: I18n.t(:'reports.include_email_subscriptions'),
            },
            {
              type: 'checkbox',
              name: :include_last_activity,
              label: I18n.t(:'reports.include_last_activity'),
            },
            {
              type: 'checkbox',
              name: :include_enrollment_evaluation,
              label: I18n.t(:'reports.include_enrollment_evaluation'),
            },
            {
              type: 'checkbox',
              name: :combine_enrollment_info,
              label: I18n.t(:'reports.combine_enrollment_info'),
            },
            {
              type: 'text_field',
              name: :zip_password,
              options: {
                placeholder: I18n.t(:'reports.zip_password'),
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
      @include_top_location =
        job.options['include_top_location']
      @include_access_groups =
        job.options['include_access_groups']
      @include_profile =
        job.options['include_profile']
      @include_auth =
        job.options['include_auth']
      @include_consents =
        job.options['include_consents']
      @include_features =
        job.options['include_features']
      @include_email_subscriptions =
        job.options['include_email_subscriptions']
      @include_last_activity =
        job.options['include_last_activity']
      @include_enrollment_evaluation =
        job.options['include_enrollment_evaluation']
      @combine_enrollment_info =
        job.options['combine_enrollment_info']
    end

    def generate!
      csv_file 'UserReport', headers, &method(:each_user)
    end

    private

    def headers
      @headers ||= [
        @de_pseudonymized ? 'User ID' : 'User Pseudo ID',
      ].tap do |headers|
        if @de_pseudonymized
          headers.append(
            'Full Name',
            'Email',
            'Birth Date',
          )
        end

        headers.append(
          'Age Group',
          'Language',
          'Created',
        )

        headers.append('Access Groups') if @include_access_groups

        if @include_top_location
          headers.append(
            'Top Country (Code)',
            'Top Country (Name)',
            'Top City',
          )
        end

        headers.concat(profile_config.all_titles) if @include_profile

        headers.concat(auth_fields.headers) if @include_auth && @de_pseudonymized

        headers.concat(treatments.map {|t| "Consent: #{t['name']}" }) if @include_consents

        headers.concat(reportable_features.map {|f| "Feature: #{f}" }) if @include_features

        if @include_email_subscriptions
          headers.append(
            'Global Announcements Subscribed',
            'Course Announcements Subscribed',
          )
        end

        headers.append('Last Activity') if @include_last_activity

        if @include_enrollment_evaluation
          headers.append('First Enrollment')
          headers.concat(courses.values.map {|course| course['course_code'] })
        end
      end
    end

    def each_user
      # Initialize access groups to preload some data.
      access_groups if @include_access_groups

      index = 0

      users_promise =
        Xikolo.paginate_with_retries(max_retries: 5, wait: 90.seconds) do
          account_service.rel(:users).get(confirmed: true, per_page: 250)
        end

      users_promise.each_item do |user, page|
        values = [
          @de_pseudonymized ? user['id'] : Digest::SHA256.hexdigest(user['id']),
        ]

        if @de_pseudonymized
          values.append(
            escape_csv_string(user['full_name']),
            user['email'],
            user['born_at'],
          )
        end

        age_group = BirthDate.new(user['born_at']).age_group_at(DateTime.now)

        values.append(
          age_group,
          user['language'],
          user['created_at'],
        )

        if @include_access_groups
          memberships = access_groups.memberships_for(user['id'])
          values.append(escape_csv_string(memberships.join('; ')))
        end

        if @include_top_location
          user_top_country = top_country(user)
          user_top_city = top_city(user)

          values.append(
            user_top_country,
            suppress(IsoCountryCodes::UnknownCodeError) do
              IsoCountryCodes.find(user_top_country)&.name
            end,
            user_top_city,
          )
        end

        if @include_profile
          profile = Xikolo::RetryingPromise.new(
            Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
              user.rel(:profile).get
            end,
          ).value!.first

          values.concat(profile_config.for(profile).values)
        end

        values.concat(auth_fields.values(user['id'])) if @include_auth && @de_pseudonymized

        if @include_consents
          consents = Xikolo::RetryingPromise.new(
            Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
              user.rel(:consents).get
            end,
          ).value!.first

          consent_values = treatments.map do |t|
            consents.find {|c| c['name'] == t['name'] }&.dig('consented') || ''
          end

          values.concat(consent_values)
        end

        if @include_features
          features = Xikolo::RetryingPromise.new(
            Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
              user.rel(:features).get
            end,
          ).value!.first

          values.concat(reportable_features.map {|f| features.key?(f) || '' })
        end

        if @include_email_subscriptions
          preferences = Xikolo::RetryingPromise.new(
            Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
              user.rel(:preferences).get
            end,
          ).value!.first&.dig('properties')

          values.append(
            global_announcements_subscribed(preferences) || '',
            course_announcements_subscribed(preferences) || '',
          )
        end

        values.append(last_activity(user)&.dig('timestamp')) if @include_last_activity

        if @include_enrollment_evaluation
          enrollments = load_all_user_enrollments(user['id'])

          values.append(
            first_course(enrollments),
            *user_course_states(enrollments),
          )
        end

        yield values

        index += 1
        @job.progress_to(index, of: page.response.headers['X_TOTAL_COUNT'])
      end
    end

    def global_announcements_subscribed(preferences)
      preferences.fetch(
        'notification.email.global', 'true'
      ) == 'true' && preferences.fetch(
        'notification.email.news.announcement', 'true'
      ) == 'true'
    end

    def course_announcements_subscribed(preferences)
      preferences.fetch(
        'notification.email.global', 'true'
      ) == 'true' && preferences.fetch(
        'notification.email.course.announcement', 'true'
      ) == 'true'
    end

    def top_country(user)
      Lanalytics::Metric::UserCourseCountry.query(user_id: user['id'])
    end

    def top_city(user)
      Lanalytics::Metric::UserCourseCity.query(user_id: user['id'])
    end

    def last_activity(user)
      Lanalytics::Metric::LastActivity.query(user_id: user['id'])
    end

    def first_course(enrollments)
      return '' if enrollments.count == 0

      first_enrollment = enrollments
        .select {|e| e['created_at'] }
        .min_by {|e| Time.zone.parse(e['created_at']) }

      return '' unless first_enrollment &&
                       courses.key?(first_enrollment['course_id'])

      courses.dig(first_enrollment['course_id'], 'course_code')
    end

    def user_course_states(enrollments)
      # Calculate the "state" for each course the user took
      course_states = enrollments.each_with_object({}) do |enrollment, states|
        if @combine_enrollment_info
          # '': not enrolled
          state = 'e' # enrolled
          state = 'v' if enrollment.dig('visits', 'visited').to_f > 0
          state = 'cc' if enrollment['completed']
          state = 'cop' if enrollment.dig(
            'certificates', 'confirmation_of_participation'
          )
          state = 'roa' if enrollment.dig(
            'certificates', 'record_of_achievement'
          )
          states[enrollment['course_id']] = state
        else
          states[enrollment['course_id']] = enrollment.dig(
            'points', 'percentage'
          )
        end
      end

      # ...and finally map them to all course columns
      courses.keys.map {|course_id| course_states[course_id] }
    end

    def courses
      @courses ||= load_all_courses
    end

    def load_all_courses
      courses = {}

      courses_promise =
        Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
          course_service.rel(:courses).get(
            groups: 'any',
            public: true,
          )
        end

      courses_promise.each_item do |course|
        courses[course['id']] = course
      end

      courses
    end

    def load_all_user_enrollments(user_id)
      enrollments = []

      enrollments_promise =
        Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
          course_service.rel(:enrollments).get(
            user_id: user_id,
            learning_evaluation: true,
            deleted: true,
            per_page: 200,
          )
        end

      enrollments_promise.each_item do |enrollment|
        enrollments << enrollment
      end

      enrollments
    end

    def treatments
      @treatments ||= Xikolo::RetryingPromise.new(
        Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
          account_service.rel(:treatments).get
        end,
      ).value!.first
    end

    def reportable_features
      Lanalytics.config.reports['features'] || []
    end

    def profile_config
      @profile_config ||= if @de_pseudonymized
                            ProfileFieldConfiguration.de_pseudonymized
                          else
                            ProfileFieldConfiguration.pseudonymized
                          end
    end

    def account_service
      @account_service ||= Restify.new(:account).get.value!
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end

    def access_groups
      @access_groups ||= AccessGroups.new
    end

    def auth_fields
      @auth_fields ||= AuthFields.new
    end
  end
end
# rubocop:enable all
