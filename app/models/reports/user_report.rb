module Reports
  class UserReport < Base
    def initialize(job)
      super

      @deanonymized = job.options['deanonymized']
      @include_top_location = job.options['include_top_location']
      @include_profile = job.options['include_profile']
      @include_primary_email_suspended = job.options['include_primary_email_suspended']
      @include_global_ann_subscribed = job.options['include_global_ann_subscribed']
      @include_last_activity = job.options['include_last_activity']
      @include_enrollment_evaluation = job.options['include_enrollment_evaluation']
      @combine_enrollment_info = job.options['combine_enrollment_info']
    end

    def generate!
      csv_file 'UserReport', headers, &method(:each_user)
    end

    private

    def headers
      ['User ID'].tap do |headers|
        if @deanonymized
          headers.concat [
            'First Name',
            'Last Name',
            'Email'
          ]
        end

        headers.concat [
          'Language',
          'Affiliated',
          'Created',
          'Birth Date'
        ]

        if @include_top_location
          headers.concat [
            'Top Country (Code)',
            'Top Country (Name)',
            'Top City'
          ]
        end

        if @include_profile
          headers.concat ProfileFields.all_titles(@deanonymized)
        end

        if @include_primary_email_suspended
          headers.concat ['Primary Email Suspended']
        end

        if @include_global_ann_subscribed
          headers.concat ['Global Announcements Subscribed']
        end

        if @include_last_activity
          headers.concat ['Last Activity']
        end

        if @include_enrollment_evaluation
          headers.concat ['First Enrollment']
          headers.concat courses.values.map { |course| course['course_code'] }
        end

      end
    end

    def each_user
      index = 0
      Xikolo.paginate(
        account_service.rel(:users).get(
          confirmed: true, per_page: 500
        )
      ) do |user, page|
        values = [@deanonymized ? user['id'] : Digest::SHA256.hexdigest(user['id'])]

        if @deanonymized
          values += [
            escape_csv_string(user['first_name']),
            escape_csv_string(user['last_name']),
            user['email']
          ]
        end

        values += [
          user['language'],
          user['affiliated'] || '',
          user['created_at'],
          user['born_at']
        ]

        if @include_top_location
          user_top_country = top_country(user)
          user_top_city = top_city(user)

          values += [
            user_top_country,
            suppress(IsoCountryCodes::UnknownCodeError) { IsoCountryCodes.find(user_top_country).name },
            user_top_city
          ]
        end

        if @include_profile
          profile = user.rel(:profile).get.value!
          profile_fields = ProfileFields.new(profile, @deanonymized)
          values += profile_fields.values
        end

        if @include_primary_email_suspended
          features = user.rel(:features).get.value!
          values += [features.key?('primary_email_suspended') || '']
        end

        if @include_global_ann_subscribed
          preferences = user.rel(:preferences).get.then { |preferences| preferences['properties'] }.value!
          values += [global_announcements_subscribed(preferences) || '']
        end

        if @include_last_activity
          values += [
            last_activity(user)&.dig('timestamp')
          ]
        end

        if @include_enrollment_evaluation
          enrollments = course_service.rel(:enrollments).get(
            user_id: user['id'], learning_evaluation: true, deleted: true, per_page: 200
          ).value!

          values += [
            first_course(enrollments),
            *user_course_states(enrollments)
          ]
        end

        yield values

        index += 1
        @job.progress_to(index, of: page.response.headers['X_TOTAL_COUNT'])
      end
    end

    def global_announcements_subscribed(preferences)
      preferences.fetch('notification.email.global', 'true') == 'true' &&
        preferences.fetch('notification.email.news.announcement', 'true') == 'true'
    end

    def top_country(user)
      Lanalytics::Metric::UserCourseCountry.query(user_id: user['id'])
    rescue
      ''
    end

    def top_city(user)
      Lanalytics::Metric::UserCourseCity.query(user_id: user['id'])
    rescue
      ''
    end

    def last_activity(user)
      Lanalytics::Metric::LastActivity.query(user_id: user['id'])
    rescue
      ''
    end

    def first_course(enrollments)
      return '' if enrollments.count == 0

      first_enrollment = enrollments
                           .select { |e| e['created_at'] }
                           .sort_by { |e| DateTime.parse(e['created_at']) }
                           .first

      return '' unless first_enrollment && courses.key?(first_enrollment['course_id'])

      courses.dig(first_enrollment['course_id'], 'course_code')
    end

    def user_course_states(enrollments)
      # Calculate the "state" for each course the user took
      course_states = enrollments.each_with_object({}) do |enrollment, states|
        if @combine_enrollment_info
          # '': not enrolled
          # e: enrolled
          # v: visited
          # p: achieved points
          # c: completed
          # r: RoA
          state = 'e'
          state = 'v' if enrollment.dig('visits', 'visited').to_f > 0
          state = 'p' if enrollment.dig('points', 'percentage').to_f > 0
          state = 'c' if enrollment['completed']
          state = 'r' if enrollment.dig('certificates', 'record_of_achievement')
          states[enrollment['course_id']] = state
        else
          states[enrollment['course_id']] = enrollment.dig('points', 'percentage')
        end
      end

      # ...and finally map them to all course columns
      courses.keys.map { |course_id| course_states[course_id] }
    end

    def courses
      @courses ||= load_all_courses
    end

    def load_all_courses
      courses = {}
      Xikolo.paginate(
        course_service.rel(:courses).get(
          affiliated: true, public: true
        )
      ) do |course|
        courses[course['id']] = course
      end
      courses
    end

    def account_service
      @account_service ||= Xikolo.api(:account).value!
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end
  end
end
