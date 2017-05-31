module Reports
  class CourseReport < Base
    def initialize(job, params = {})
      super

      @anonymize = params[:privacy_flag]
      @extended = params[:extended_flag]
      @include_sections = true
      @include_all_quizzes = params[:include_all_quizzes]
    end

    def generate!
      @job.update(annotation: course['course_code'])

      csv_file "CourseReport_#{course['course_code']}", headers, &method(:each_row)
    end

    private

    def each_row
      index = 0
      courses.each_with_index do |course, course_index|
        Xikolo::Course::Enrollment.each_item(
          course_id: course['id'], per_page: 1, deleted: true, learning_evaluation: 'true'
        ) do |enrollment, enrollments|
          user = account_service.rel(:user).get(id: enrollment.user_id).value!

          Restify::Promise.new(
            user.rel(:profile).get,
            pinboard_service.rel(:statistic).get(id: course['id'], user_id: user['id']),
            course_service.rel(:progresses).get(user_id: user.id, course_id: course['id'])
          ) do |profile, stat_pinboard, progresses|
            birth_compare_date = course['start_date'] ? DateTime.parse(course['start_date']) : DateTime.now
            age = user.born_at.present? ? ((birth_compare_date - user.born_at) / 365).to_i : '-99'

            values = [
              @anonymize ? Digest::SHA256.hexdigest(user.id) : user.id,
              enrollment.created_at,
              enrollment.created_at.strftime('%Y-%m-%d'),
              first_enrollment?(enrollment),
              user.created_at.strftime('%Y-%m-%d'),
              user.language,
              user.affiliated,
              user.born_at,
              age,
              user.born_at.present? ? age_group_from_age(age) : '-99'
            ]

            unless @anonymize
              values += [
                user.first_name,
                user.last_name,
                user.email
              ]
            end

            # get elasticsearch metrics per user
            if @extended
              course_activity = fetch_metric('CourseActivity', course['id'], user.id)
              user_course_country = fetch_metric('UserCourseCountry', course['id'], user.id, :unescaped_query)

              metrics = {
                device_usage: fetch_device_usage(course['id'], user.id),
                course_activity: course_activity.present? && course_activity[:count].present? ? course_activity[:count].to_s : '-99',
                user_course_country: user_course_country.present? ? user_course_country : 'zz'
              }

              clustering_metrics = fetch_clustering_metrics(course)

              values += [
                metrics[:user_course_country],
                metrics[:device_usage][:state],
                metrics[:device_usage][:web],
                metrics[:device_usage][:mobile],
                clustering_metrics.dig(user.id, 'sessions') || '-99',
                clustering_metrics.dig(user.id, 'average_session_duration') || '-99',
                clustering_metrics.dig(user.id, 'total_session_duration') || '-99',
                clustering_metrics.dig(user.id, 'forum_activity') || '-99',
                clustering_metrics.dig(user.id, 'textual_forum_contribution') || '-99',
                clustering_metrics.dig(user.id, 'forum_observation') || '-99',
                clustering_metrics.dig(user.id, 'item_discovery') || '-99',
                clustering_metrics.dig(user.id, 'video_discovery') || '-99',
                clustering_metrics.dig(user.id, 'quiz_discovery') || '-99',
                clustering_metrics.dig(user.id, 'video_player_activity') || '-99',
                clustering_metrics.dig(user.id, 'download_activity') || '-99',
                clustering_metrics.dig(user.id, 'course_performance') || '-99',
                clustering_metrics.dig(user.id, 'quiz_performance') || '-99',
                clustering_metrics.dig(user.id, 'ungraded_quiz_performance') || '-99',
                clustering_metrics.dig(user.id, 'graded_quiz_performance') || '-99',
                clustering_metrics.dig(user.id, 'main_quiz_performance') || '-99',
                clustering_metrics.dig(user.id, 'bonus_quiz_performance') || '-99',
                metrics[:course_activity]
              ]
            end

            values += [
              (enrollment.created_at - DateTime.parse(course['start_date'])).to_i,
              *profile['fields'].map { |f| f.dig('values', 0) },
              stat_pinboard['questions'],
              stat_pinboard['answers'],
              stat_pinboard['comments_on_answers'],
              stat_pinboard['comments_on_questions'],
              stat_pinboard['questions'] + stat_pinboard['answers'] + stat_pinboard['comments_on_answers'] + stat_pinboard['comments_on_questions'],
              enrollment.points[:achieved].present? ? enrollment.points[:achieved] : '',
              enrollment.points[:percentage].present? ? enrollment.points[:percentage] : '',
              enrollment.certificates[:confirmation_of_participation].present? ? enrollment.certificates[:confirmation_of_participation] : '-99',
              enrollment.certificates[:record_of_achievement].present? ? enrollment.certificates[:record_of_achievement] : '-99',
              enrollment.certificates[:certificate].present? ? enrollment.certificates[:certificate] : '-99',
              enrollment.completed.present? ? enrollment.completed : '-99',
              enrollment.deleted.present? ? enrollment.deleted : '-99',
              enrollment.quantile.present? ? enrollment.quantile : '-99',
              enrollment.quantile.present? ? calculate_top_performance(enrollment.quantile) : '-99',
              enrollment.visits[:visited].present? ? enrollment.visits[:visited] : '',
              enrollment.visits[:percentage].present? ? enrollment.visits[:percentage] : ''
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

            all_submissions = all_user_submissions(user.id)
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
          '60+'
        else
          '70+'
      end
    end

    def fetch_device_usage(course_id, user_id)
      device_usage = fetch_metric('DeviceUsage', course_id, user_id)

      result = {}

      if device_usage != 0
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
      0
    end

    def fetch_clustering_metrics(course)
      return {} unless @extended

      clustering_metrics = %w[
        sessions
        average_session_duration
        total_session_duration
        forum_activity
        textual_forum_contribution
        forum_observation
        item_discovery
        video_discovery
        quiz_discovery
        video_player_activity
        download_activity
        course_performance
        quiz_performance
        ungraded_quiz_performance
        graded_quiz_performance
        main_quiz_performance
        bonus_quiz_performance
      ]
      result = Lanalytics::Clustering::Dimensions.query(course['id'], clustering_metrics, nil)
      result.map { |x| [x['user_uuid'], x.except('user_uuid')] }.to_h
    rescue
      {}
    end

    def calculate_top_performance(quantile)
      return '-99' unless quantile
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
        'Enrollment Day',
        'First Enrollment',
        'User created',
        'Language',
        'Affiliated',
        'Birthdate',
        'Age',
        'Age Group'
      ].tap do |headers|
        unless @anonymize
          headers.concat [
            'First Name',
            'Last Name',
            'Email'
          ]
        end

        if @extended
          headers.concat [
            'Top Country',
            'Device Usage',
            'Web Usage',
            'Mobile Usage',
            'Sessions',
            'Avg. Session Duration',
            'Total Session Duration',
            'Forum Activity',
            'Forum Textual Contribution',
            'Forum Observation',
            'Item Discovery',
            'Video Discovery',
            'Quiz Discovery',
            'Video Player Activity',
            'Download Activity',
            'Course Performance',
            'Quiz Performance',
            'Ungraded Quiz Performance',
            'Graded Quiz Performance',
            'Main Quiz Performance',
            'Bonus Quiz Performance',
            'Course Activity'
          ]
        end

        headers.concat [
          'Enrollment Delta in Days',
          custom_profile_fields.map { |f| f['title']['en'] },
          'Questions',
          'Answers',
          'Comments on Answers',
          'Comments on Questions',
          'Total Forum Items',
          'Points Achieved',
          'Points Percentage',
          'Confirmation of Participation',
          'Record of Achievement',
          'Certificate',
          'Completed',
          'Deleted',
          'Quantile',
          'Top Performance',
          'Items Visited',
          'Visited Items Percentage'
        ]

        if @include_sections
          headers.concat course_sections.map { |s| "#{s['title'].titleize} Percentage (Section)" }
          headers.concat course_sections.map { |s| "#{s['title'].titleize} Points (Section)" }
        end

        headers.concat quizzes.map { |q| "#{q['title'].titleize} Points (Quiz)" }

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

    def quizzes
      return [] unless @include_all_quizzes

      @quizzes ||= course_service.rel(:items).get(
        course_id: course['id'],
        content_type: 'quiz'
      ).value!.select { |q| %w(main selftest bonus).include? q['exercise_type'] }
    end

    def all_user_submissions(user_id)
      return {} unless @include_all_quizzes

      submissions = submission_service.rel(:quiz_submissions).get(
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
        user_id: enrollment.user_id,
        deleted: true,
        per_page: 500
      ).value!

      all_enrollments.none? { |e| DateTime.parse(e['created_at']) < enrollment.created_at }
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

    def submission_service
      @submission_service ||= Xikolo.api(:submission).value!
    end
  end
end
