module Reports
  class UserReport < Base
    def initialize(job, options = {})
      super

      @deanonymized = options['deanonymized']
      @combine_enrollment_info = options['combined_enrollment_info_flag']
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
          'Birth Date',
          'Top Country',
          'First Enrollment'
        ]

        if @deanonymized
          headers.concat custom_profile_fields.map { |f| f['title']['en'] }
        end

        headers.concat courses.values.map(&:course_code)
      end
    end

    def each_user
      index = 0
      Xikolo::Account::User.each_item(confirmed: true, per_page: 500) do |user, users|
        Restify::Promise.new(
          account_service.rel(:user).get(id: user.id).then { |user|
            user.rel(:profile).get
          },
          course_service.rel(:enrollments).get(
            user_id: user.id, learning_evaluation: true, deleted: true, per_page: 200
          )
        ) do |user_profile, user_enrollments|
          values = [@deanonymized ? user.id : Digest::SHA256.hexdigest(user.id)]

          if @deanonymized
            values += [
              escape_csv_string(user.first_name),
              escape_csv_string(user.last_name),
              user.email
            ]
          end

          values += [
            user.language,
            user.affiliated,
            user.created_at.strftime('%Y-%m-%d'),
            user.born_at,
            top_country(user),
            first_course(user_enrollments)
          ]

          if @deanonymized
            values += user_profile['fields'].map { |f| f.dig('values', 0) }
          end

          values += user_course_states(user_enrollments)

          yield values

          index += 1
          @job.progress_to(index, of: users.total_count)
        end.value!
      end

      Acfs.run
    end

    def top_country(user)
      Lanalytics::Metric::UserCourseCountry.query(
        user.id, nil, nil, nil, nil, nil, nil
      )
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

      courses[first_enrollment['course_id']].course_code
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
      Xikolo::Course::Course.each_item(affiliated: 'true', public: 'true') do |course|
        courses[course.id] = course
      end
      Acfs.run
      courses
    end

    def custom_profile_fields
      users = account_service.rel(:users).get(per_page: 1).value!

      return [] if users.empty?

      profile = users.first.rel(:profile).get.value!

      return [] unless profile

      profile['fields']
    end

    def account_service
      @account_service ||= Xikolo.api(:account).value!
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end
  end
end
