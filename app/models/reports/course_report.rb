module Reports
  class CourseReport < Base
    def initialize(job, options = {})
      super

      @deanonymized = options['deanonymized']
      @include_analytics_metrics = options['include_analytics_metrics']
      @include_profile = options['include_profile']
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

        # these metrics are fetched for all users at once from postgres
        # needs more memory but much faster performance
        if @include_analytics_metrics
          clustering_metrics = fetch_clustering_metrics(course)

          video_count ||= course_service.rel(:items).get(
            course_id: course['id'],
            content_type: 'video',
            was_available: true
          ).value!.count

          start_date =  Date.parse(course['start_date'])
          end_date =    Date.parse(course['end_date'] || Date.today)
          course_days = (end_date - start_date).to_i
        end

        Xikolo.paginate(
          course_service.rel(:enrollments).get(
            course_id: course['id'], per_page: 50, deleted: true
          )
        ) do |e, enrollment_page|
          user = account_service.rel(:user).get(id: e['user_id']).value!

          Restify::Promise.new(
            course_service.rel(:enrollments).get(
              course_id: course['id'], user_id: e['user_id'], deleted: true, learning_evaluation: true
            ).then { |array| array.first },
            pinboard_service.rel(:statistic).get(id: course['id'], user_id: user['id'])
          ) do |enrollment, stat_pinboard|
            course_start_date = as_date(course['start_date'])
            birth_compare_date = course_start_date || DateTime.now
            enrollment_date = as_date(enrollment['created_at'])
            age = user['born_at'].present? ? ((birth_compare_date - DateTime.parse(user['born_at'])) / 365).to_i : ''

            values = [
              @deanonymized ? user['id'] : Digest::SHA256.hexdigest(user['id']),
              enrollment_date,
              first_enrollment?(enrollment),
              user['created_at'],
              user['language'],
              user['affiliated'],
              as_date(user['born_at']),
              age,
              user['born_at'].present? ? age_group_from_age(age) : ''
            ]

            if @deanonymized
              values += [
                escape_csv_string(user['first_name']),
                escape_csv_string(user['last_name']),
                user['email']
              ]
            end

            if @include_profile
              profile = user.rel(:profile).get.value!
              profile_fields = ProfileFields.new(profile, @deanonymized)
              values += profile_fields.values
            end

            # get elasticsearch / postgres metrics per user
            if @include_analytics_metrics
              user_course_country = fetch_metric('UserCourseCountry', course['id'], user['id']) || ''
              user_course_city = fetch_metric('UserCourseCity', course['id'], user['id']) || ''
              device_usage = fetch_device_usage(course['id'], user['id'])
              last_visited_item = fetch_metric('LastVisitedItem', course['id'], user['id'])
              forum_activity = fetch_metric('ForumActivity', course['id'], user['id'])&.dig(:total)
              forum_read_activity = fetch_metric('ForumReadActivity', course['id'], user['id'])&.dig(:total)

              values += [
                user_course_country,
                suppress(IsoCountryCodes::UnknownCodeError) { IsoCountryCodes.find(user_course_country).name },
                user_course_city,
                device_usage['desktop web'],
                device_usage['mobile web'],
                device_usage['mobile app'],
                last_visited_item.dig('resource', 'resource_uuid') || '',
                last_visited_item.dig('timestamp') || '',
                clustering_metrics.dig(user['id'], 'sessions') || '',
                clustering_metrics.dig(user['id'], 'average_session_duration') || '',
                clustering_metrics.dig(user['id'], 'total_session_duration') || '',
                clustering_metrics.dig(user['id'], 'unique_video_play_activity') || '',
                percentage(clustering_metrics.dig(user['id'], 'unique_video_play_activity'), of: video_count) || '',
                clustering_metrics.dig(user['id'], 'unique_video_downloads_activity') || '',
                percentage(clustering_metrics.dig(user['id'], 'unique_video_downloads_activity'), of: video_count) || '',
                clustering_metrics.dig(user['id'], 'unique_slide_downloads_activity') || '',
                percentage(clustering_metrics.dig(user['id'], 'unique_slide_downloads_activity'), of: video_count) || '',
                forum_activity,
                forum_activity.to_f / course_days,
                forum_read_activity,
                clustering_metrics.dig(user['id'], 'quiz_performance') || '',
              ]
            end

            # Try to calculate enrollment delta
            if course_start_date && enrollment_date
              values << (enrollment_date - course_start_date).to_i
            else
              values << ''
            end

            values += [
              stat_pinboard['posts'],
              stat_pinboard['threads'],
              enrollment.dig('certificates', 'confirmation_of_participation') || '',
              enrollment.dig('certificates', 'record_of_achievement') || '',
              enrollment.dig('certificates', 'certificate') || '',
              enrollment['completed'] || '',
              enrollment['deleted'] || '',
              enrollment['quantile'] || '',
              enrollment['quantile'].present? ? calculate_top_performance(enrollment['quantile']) : '',
              enrollment.dig('visits', 'visited'),
              enrollment.dig('visits', 'percentage'),
              enrollment.dig('points', 'achieved'),
              enrollment.dig('points', 'percentage')
            ]

            # For each section, append visit percentage and total graded points
            if @include_sections
              progresses = course_service.rel(:progresses).get(user_id: user['id'], course_id: course['id']).value!

              values += course_sections.map do |s|
                progresses.find { |p| p['resource_id'] == s['id'] }&.dig('visits', 'user')
              end

              values += course_sections.map do |s|
                progresses.find { |p| p['resource_id'] == s['id'] }&.dig('visits', 'percentage')
              end

              values += course_sections.map do |s|
                p = progresses.find { |p| p['resource_id'] == s['id'] }
                if p
                  main_points = p.dig('main_exercises', 'graded_points').to_f.round(2)
                  bonus_points = p.dig('bonus_exercises', 'graded_points').to_f.round(2)
                  main_points + bonus_points
                end
              end

              values += course_sections.map do |s|
                p = progresses.find { |p| p['resource_id'] == s['id'] }
                if p
                  main_points = p.dig('main_exercises', 'graded_points').to_f.round(2)
                  bonus_points = p.dig('bonus_exercises', 'graded_points').to_f.round(2)
                  points = main_points + bonus_points
                  max_points = p.dig('main_exercises', 'max_points').to_f.round(2)
                  percentage = (points / max_points * 100).round(2)
                  percentage&.nan? ? nil : percentage
                end
              end
            end

            all_submissions = all_user_submissions(user['id'])
            values += quizzes.map { |q| all_submissions.dig(q['content_id'], 'points') || 0 }

            values += [course['course_code']]

            yield values

            index += 1
            @job.progress_to(
              (course_index * enrollment_page.response.headers['X_TOTAL_COUNT'].to_i) + index,
              of: courses.count * enrollment_page.response.headers['X_TOTAL_COUNT'].to_i
            )
          end.value!
        end
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

      device_usage[:behavior][:usage].each do |usage|
        result[usage[:category]] = usage[:total_activity].to_s
      end

      result
    end

    def fetch_metric(metric, course_id, user_id)
      metric = "Lanalytics::Metric::#{metric}".constantize
      metric.query(user_id: user_id, course_id: course_id)
    rescue
      nil
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

        if @include_profile
          headers.concat ProfileFields.all_titles(@deanonymized)
        end

        if @include_analytics_metrics
          headers.concat [
            'Top Country (Code)',
            'Top Country (Name)',
            'Top City',
            'Desktop Web Activity',
            'Mobile Web Activity',
            'Mobile App Activity',
            'Last Visited Item',
            'Last Visited Item Timestamp',
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
            'Forum Read Activity',
            'Quiz Performance'
          ]
        end

        headers.concat [
          'Enrollment Delta in Days',
          'Forum Posts',
          'Forum Threads',
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
          'Points Percentage'
        ]

        if @include_sections
          headers.concat course_sections.map { |s| "#{s['title'].titleize} Items Visited (Section)" }
          headers.concat course_sections.map { |s| "#{s['title'].titleize} Items Visited Percentage (Section)" }
          headers.concat course_sections.map { |s| "#{s['title'].titleize} Points (Section)" }
          headers.concat course_sections.map { |s| "#{s['title'].titleize} Points Percentage (Section)" }
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
        published: true,
        include_alternatives: true
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

      if @quizzes.nil?
        @quizzes = []
        Xikolo.paginate(
          course_service.rel(:items).get(
            course_id: course['id'],
            content_type: 'quiz'
          )
        ) do |quiz|
          if %w(main selftest bonus).include? quiz['exercise_type']
            @quizzes.append(quiz)
          end
        end
      end

      @quizzes
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

    def percentage(n, of:)
      return if n.blank? || of == 0
      format("%.2f", n.to_f / of.to_f * 100.0)
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
