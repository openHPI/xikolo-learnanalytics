# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/BlockLength
# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity
module Reports
  class UserReport < Base
    def initialize(job)
      super

      @deanonymized =
        job.options['deanonymized']
      @include_top_location =
        job.options['include_top_location']
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
        'User ID',
      ].tap do |headers|
        if @deanonymized
          headers.append(
            'Full Name',
            'Email',
          )
        end

        headers.append(
          'Language',
          'Affiliated',
          'Created',
          'Birth Date',
        )

        if @include_top_location
          headers.append(
            'Top Country (Code)',
            'Top Country (Name)',
            'Top City',
          )
        end

        if @include_profile
          headers.concat(ProfileFields.all_titles(@deanonymized))
        end

        if @include_auth && @deanonymized
          headers.concat(reportable_auth_fields.map {|f| "Auth: #{f}" })
        end

        if @include_consents
          headers.concat(treatments.map {|t| "Consent: #{t.name}" })
        end

        if @include_features
          headers.concat(reportable_features.map {|f| "Feature: #{f}" })
        end

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
      index = 0

      users_promise =
        Xikolo.paginate_with_retries(max_retries: 5, wait: 90.seconds) do
          account_service.rel(:users).get(confirmed: true, per_page: 250)
        end

      users_promise.each_item do |user, page|
        values = [
          @deanonymized ? user['id'] : Digest::SHA256.hexdigest(user['id']),
        ]

        if @deanonymized
          values.append(
            escape_csv_string(user['full_name']),
            user['email'],
          )
        end

        values.append(
          user['language'],
          user['affiliated'] || '',
          user['created_at'],
          user['born_at'],
        )

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

          profile_fields = ProfileFields.new(profile, @deanonymized)

          values.concat(profile_fields.values)
        end

        if @include_auth && @deanonymized
          authorizations = Xikolo::RetryingPromise.new(
            Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
              account_service.rel(:authorizations).get(user: user['id'])
            end,
          ).value!.first

          auth_values = reportable_auth_fields.map do |f|
            authorizations
              .select {|auth| auth['provider'] == f.split('.').first }
              .map {|auth| auth.dig(*f.split('.').drop(1)) }
              .compact
              .join(',')
          end

          values.concat(auth_values)
        end

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

        if @include_last_activity
          values.append(last_activity(user)&.dig('timestamp'))
        end

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
      Xikolo.config.reports['features'] || []
    end

    def reportable_auth_fields
      Xikolo.config.reports['auth_fields'] || []
    end

    def account_service
      @account_service ||= Xikolo.api(:account).value!
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end
  end
end
# rubocop:enable all
