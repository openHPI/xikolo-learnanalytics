module Reports
  class CourseReport < Base
    def initialize(job, options = {})
      super

      @deanonymized = options['deanonymized']
      @extended = options['extended_flag']
      @include_sections = true
      @include_all_quizzes = options['include_all_quizzes']
    end

    def generate!
      @job.update(annotation: course['course_code'])

      csv_file "CourseReport_#{course['course_code']}", headers, &method(:each_row)
    end

    private

    def each_row
      courses.each_with_index do |course, course_index|
        index = 0

        Xikolo::Course::Enrollment.each_item(
          course_id: course['id'], per_page: 50, deleted: true
        ) do |e, enrollments|
          user = account_service.rel(:user).get(id: e.user_id).value!

          Restify::Promise.new(
            user.rel(:profile).get,
            course_service.rel(:enrollments).get(
              course_id: course['id'], user_id: e.user_id, deleted: true, learning_evaluation: true
            ).then { |array| array.first },
            pinboard_service.rel(:statistic).get(id: course['id'], user_id: user['id']),
            course_service.rel(:progresses).get(user_id: user['id'], course_id: course['id'])
          ) do |profile, enrollment, stat_pinboard, progresses|
            course_start_date = as_date(course['start_date'])
            birth_compare_date = course_start_date || DateTime.now
            enrollment_date = as_date(enrollment['created_at'])
            age = user['born_at'].present? ? ((birth_compare_date - DateTime.parse(user['born_at'])) / 365).to_i : ''

            values = [
              @deanonymized ? user['id'] : Digest::SHA256.hexdigest(user['id']),
              enrollment_date&.strftime('%Y-%m-%d'),
              first_enrollment?(enrollment),
              DateTime.parse(user['created_at']).strftime('%Y-%m-%d'),
              user['language'],
              user['affiliated'],
              as_date(user['born_at']),
              age,
              user['born_at'].present? ? age_group_from_age(age) : ''
            ]

            if @deanonymized
              values += [
                user['first_name'],
                user['last_name'],
                user['email']
              ]
            end

            # get elasticsearch metrics per user
            if @extended
              course_activity = fetch_metric('CourseActivity', course['id'], user['id']) || {}
              user_course_country = fetch_metric('UserCourseCountry', course['id'], user['id'], :unescaped_query) || ''
              user_course_city = fetch_metric('UserCourseCity', course['id'], user['id'], :unescaped_query) || ''

              metrics = {
                device_usage: fetch_device_usage(course['id'], user['id']),
                course_activity: course_activity[:count] || '',
                user_course_country: user_course_country.present? ? user_course_country : '',
                user_course_city: user_course_city.present? ? user_course_city : ''
              }

              clustering_metrics = fetch_clustering_metrics(course)

              values += [
                metrics[:user_course_country],
                metrics[:user_course_city],
                metrics[:device_usage][:state],
                metrics[:device_usage][:web],
                metrics[:device_usage][:mobile],
                clustering_metrics.dig(user['id'], 'sessions') || '',
                clustering_metrics.dig(user['id'], 'average_session_duration') || '',
                clustering_metrics.dig(user['id'], 'total_session_duration') || '',
                clustering_metrics.dig(user['id'], 'forum_activity') || '',
                clustering_metrics.dig(user['id'], 'forum_observation') || '',
                clustering_metrics.dig(user['id'], 'video_player_activity') || '',
                clustering_metrics.dig(user['id'], 'download_activity') || '',
                clustering_metrics.dig(user['id'], 'quiz_performance') || '',
                metrics[:course_activity]
              ]
            end

            # Try to calculate enrollment delta
            if course_start_date && enrollment_date
              values << (enrollment_date - course_start_date).to_i
            else
              values << ''
            end

            if @deanonymized
              values.concat profile['fields'].map { |f| f.dig('values', 0) }
            end

            values += [
              stat_pinboard['posts'],
              stat_pinboard['threads'],
              enrollment.dig('points', 'achieved'),
              enrollment.dig('points', 'percentage'),
              enrollment.dig('certificates', 'confirmation_of_participation') || '',
              enrollment.dig('certificates', 'record_of_achievement') || '',
              enrollment.dig('certificates', 'certificate') || '',
              enrollment['completed'] || '',
              enrollment['deleted'] || '',
              enrollment['quantile'] || '',
              enrollment['quantile'].present? ? calculate_top_performance(enrollment['quantile']) : '',
              enrollment.dig('visits', 'visited'),
              enrollment.dig('visits', 'percentage')
            ]

            # For each section, append visit percentage and total graded points
            if @include_sections
              progresses.pop # Last progress element is for the entire course

              values += progresses.map { |section| section.dig('visits', 'percentage') }
              values += progresses.map { |section|
                main_points = section.dig('main_exercises', 'graded_points').to_f.round(2)
                bonus_points = section.dig('bonus_exercises', 'graded_points').to_f.round(2)
                main_points + bonus_points
              }
            end

            all_submissions = all_user_submissions(user['id'])
            values += quizzes.map { |q| all_submissions.dig(q['content_id'], 'points') || 0 }

            values += [course['course_code']]

            yield values

            index += 1
            @job.progress_to(
              (course_index * enrollments.total_count) + index,
              of: courses.count * enrollments.total_count
            )
          end.value!
        end

        Acfs.run
      end
    end

    def age_group_from_age(age)
      case age.to_i
        when 0...20
          '0+'
        when 20...30
          '20+'
        when 30...40
          '30+'
        when 40...50
          '40+'
        when 50...60
          '50+'
        when 60...70
          '60+'
        else
          '70+'
      end
    end

    def fetch_device_usage(course_id, user_id)
      device_usage = fetch_metric('DeviceUsage', course_id, user_id)

      result = {}

      if device_usage
        result[:state] = device_usage[:behavior][:state]
        device_usage[:behavior][:usage].each do |usage|
          result[usage[:category].to_sym] = usage[:total_activity].to_s
        end
      else
        result[:state] = 'unknown'
      end
      result[:mobile] = '0' unless result.key?(:mobile)
      result[:web] = '0' unless result.key?(:web)

      result
    end

    def fetch_metric(metric, course_id, user_id, exec = :query)
      metric = "Lanalytics::Metric::#{metric}".constantize
      metric.public_send(exec,
                         user_id,
                         course_id,
                         nil, nil, nil, nil, nil)
    rescue
      nil
    end

    def fetch_clustering_metrics(course)
      return {} unless @extended

      clustering_metrics = %w[
        sessions
        average_session_duration
        total_session_duration
        forum_activity
        forum_observation
        video_player_activity
        download_activity
        quiz_performance
      ]
      result = Lanalytics::Clustering::Dimensions.query(course['id'], clustering_metrics, nil)
      result.map { |x| [x['user_uuid'], x.except('user_uuid')] }.to_h
    rescue
      {}
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

    def headers
      @headers ||= [
        'User ID',
        'Enrollment Date',
        'First Enrollment',
        'User created',
        'Language',
        'Affiliated',
        'Birth Date',
        'Age',
        'Age Group'
      ].tap do |headers|
        if @deanonymized
          headers.concat [
            'First Name',
            'Last Name',
            'Email'
          ]
        end

        if @extended
          headers.concat [
            'Top Country',
            'Top City',
            'Device Usage',
            'Web Usage',
            'Mobile Usage',
            'Sessions',
            'Avg. Session Duration',
            'Total Session Duration',
            'Forum Activity',
            'Forum Observation',
            'Video Player Activity',
            'Download Activity',
            'Quiz Performance',
            'Course Activity'
          ]
        end

        headers << 'Enrollment Delta in Days'

        if @deanonymized
          headers.concat custom_profile_fields.map { |f| f['title']['en'] }
        end

        headers.concat [
          'Forum Posts',
          'Forum Threads',
          'Points Achieved',
          'Points Percentage',
          'Confirmation of Participation',
          'Record of Achievement',
          'Qualified Certificate',
          'Course Completed',
          'Course Deleted',
          'Quantile',
          'Top Performance',
          'Items Visited',
          'Visited Items Percentage'
        ]

        if @include_sections
          headers.concat course_sections.map { |s| "#{s['title'].titleize} Percentage (Section)" }
          headers.concat course_sections.map { |s| "#{s['title'].titleize} Points (Section)" }
        end

        headers.concat quiz_column_headers

        headers.concat ['Course Code']
      end
    end

    def courses
      @courses ||= [course_service.rel(:course).get(id: @job.task_scope).value!]
    end

    def course
      courses.first
    end

    def course_sections
      @course_sections ||= course_service.rel(:sections).get(
        course_id: course['id'],
        published: true
      ).value!
    end

    def quiz_column_headers
      quizzes.map { |q|
        section = course_sections.find { |s| s['id'] == q['section_id'] } || {'title' => ''}
        "#{section['title'].titleize} - #{q['title'].titleize} Points (Quiz)"
      }
    end

    def quizzes
      return [] unless @include_all_quizzes

      @quizzes ||= course_service.rel(:items).get(
        course_id: course['id'],
        content_type: 'quiz'
      ).value!.select { |q| %w(main selftest bonus).include? q['exercise_type'] }
    end

    def all_user_submissions(user_id)
      return {} unless @include_all_quizzes

      submissions = quiz_service.rel(:quiz_submissions).get(
        user_id: user_id,
        only_submitted: true,
        course_id: course['id']
      ).value!

      all_submissions = submissions.data

      while submissions.rel?(:next)
        submissions = submissions.rel(:next).get.value!
        all_submissions += submissions
      end

      # Get last submission for every quiz
      all_submissions
        .group_by { |submission| submission['quiz_id'] }
        .map { |quiz_id, arr|
          last_submission = arr.sort_by { |s| DateTime.parse(s['quiz_submission_time']) }.last
          [quiz_id, last_submission]
        }.to_h
    end

    def first_enrollment?(enrollment)
      all_enrollments = course_service.rel(:enrollments).get(
        user_id: enrollment['user_id'],
        deleted: true,
        per_page: 500
      ).value!

      compare_date = as_date(enrollment['created_at'])

      return '' unless compare_date

      all_enrollments
        .map { |e| as_date(e['created_at']) }
        .compact
        .none? { |date| date < compare_date }
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

    def pinboard_service
      @pinboard_service ||= Xikolo.api(:pinboard).value!
    end

    def quiz_service
      @quiz_service ||= Xikolo.api(:quiz).value!
    end

    def as_date(string_or_nil)
      string_or_nil && DateTime.parse(string_or_nil)
    end
  end
end
