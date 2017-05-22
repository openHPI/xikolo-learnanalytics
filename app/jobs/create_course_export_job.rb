class CreateCourseExportJob < CreateExportJob
  queue_as :default

  def perform(job_id, password, user_id, course_id, privacy_flag, extended_flag)
    job = find_and_save_job(job_id)

    begin
      course = Xikolo::Course::Course.find(course_id)
      Acfs.run
      job.annotation = course.course_code.to_s
      job.save
      temp_report = create_report(job_id, [course_id], privacy_flag, extended_flag)
      csv_name = get_tempdir.to_s + '/CourseExport_' + course.course_code.to_s + '_' + DateTime.now.strftime('%Y-%m-%d') + '.csv'
      create_file(job_id, csv_name, temp_report.path, false, false, password, user_id, course_id, nil)
    rescue => error
      Sidekiq.logger.error error.inspect
      job.status = 'failing'
      job.save
      File.delete(temp_report) if File.exist?(temp_report)
    end
  end

  protected

  def create_report(job_id, course_ids, privacy_flag = false, extended_flag = false)
    if course_ids.length == 1
      file = Tempfile.open("course_export_#{job_id.to_s}", get_tempdir)
    elsif course_ids.length > 1
      file = Tempfile.open("course_collection_export_#{job_id.to_s}", get_tempdir)
    else
      raise ArgumentError, 'course_ids needs to be an array with one or more ids'
    end

    csv = CSV.new(file)

    headers = []

    course_ids.each.with_index(1) do |course_id, course_index|
      course = Xikolo::Course::Course.find(course_id)
      Acfs.run

      birth_compare_date = course.start_date.present? ? course.start_date : DateTime.now

      page_size = 50
      pager = 1

      clustering_metrics = {}

      loop do
        enrollments = Xikolo::Course::Enrollment.where(course_id: course_id, page: pager, per_page: page_size, deleted: true)
        Acfs.run

        if headers.length == 0 && enrollments.current_page == 1 && enrollments.size > 0
          update_progress(job_id, enrollments, 1, course_ids.length, course_index)

          enrolled_user = Xikolo::Account::User.find(enrollments.first.user_id) if enrollments.first.present?
          Acfs.run

          profile_presenter = Account::ProfilePresenter.new(enrolled_user)
          course_presenter = Course::ProgressPresenter.build(enrolled_user, course)
          Acfs.run

          headers += ['User ID',
                      'Enrollment Date',
                      'Enrollment Day',
                      'First Enrollment',
                      'User created',
                      'Language',
                      'Affiliated',
                      'Birthdate',
                      'Age',
                      'Age Group']

          unless privacy_flag
            headers += ['First Name',
                        'Last Name',
                        'Email']
          end

          if extended_flag
            headers += ['Top Country',
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
                        #'Question Response Time'
                        ]
          end

          headers += ['Enrollment Delta in Days',
                      *profile_presenter.fields.map { |f| f.name.titleize },
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
                      'Visited Items Percentage']

          if course_ids.length == 1
            headers += [*course_presenter.sections.map { |f| f.title.titleize + ' Percentage' },
                        *course_presenter.sections.map { |f| f.title.titleize + ' Points' }]
          end

          headers += ['Course Code']

          csv << headers
          csv.flush

          # get postgres metrics for all users in course
          if extended_flag
            clustering_metrics = fetch_clustering_metrics(course_id)
            Sidekiq.logger.info "[Clustering Metrics] Number of Users: #{clustering_metrics.size}"
          end

        end

        enrollments.each.with_index(1) do |enrollment, index|
          begin
            update_progress(job_id, enrollments, index, course_ids.length, course_index)

            user = Xikolo::Account::User.find(enrollment.user_id)
            full_enrollment = Xikolo::Course::Enrollment.find_by(user_id: enrollment.user_id, course_id: course_id, deleted: true, learning_evaluation: 'true')
            Acfs.run

            item = {}
            item[:user] = UserPresenter.create(user)
            item[:profile] = Account::ProfilePresenter.new(user)
            item[:data] = full_enrollment
            item[:stat_pinboard] = Xikolo::Pinboard::Statistic.find(course.id, params: {user_id: user.id})
            #for user and profile presenter
            item[:cp] = Course::ProgressPresenter.build(user, course)
            Acfs.run

            item[:age] = item[:user].born_at.present? ? ((birth_compare_date - item[:user].born_at) / 365).to_i : '-99'
            item[:age_group] = item[:user].born_at.present? ? age_group_from_age(item[:age]) : '-99'

            # get elasticsearch metrics per user
            if extended_flag
              metrics = ActiveSupport::HashWithIndifferentAccess.new

              metrics[:device_usage] = fetch_device_usage(course_id, user.id)

              course_activity = fetch_metric('CourseActivity', course_id, user.id)
              metrics[:course_activity] = course_activity.present? && course_activity[:count].present? ? course_activity[:count].to_s : '-99'

              # question_response_time = fetch_metric('QuestionResponseTime', course_id, user.id)
              # metrics[:question_response_time] = question_response_time.present? && question_response_time[:average].present? ? question_response_time[:average].to_s : '-99'

              user_course_country = fetch_metric('UserCourseCountry', course_id, user.id, :unescaped_query)
              metrics[:user_course_country] = user_course_country.present? ? user_course_country : 'zz'
            end

            if true
              quizzes = Xikolo.api(:course).value!.rel(:items).get(
                course_id: course_id,
                content_type: 'quiz',
                exercise_type: %w(main selftest bonus)
              ).value!

              submissions = Xikolo.api(:submission).value!.rel(:quiz_submissions).get(
                user_id: user.id,
                only_submitted: true,
                quiz_id: quizzes.map { |q| q['id'] }
              ).value!
              
              all_submissions = submissions

              while submissions.rel?(:next)
                submissions = submissions.rel(:next).get.value!
                all_submissions << submissions
              end

              # get last submission for every quiz
              submissions = submissions.group_by { |submission| submission['quiz_id'] }
                              .map do |_, arr|
                                arr.sort_by { |s| DateTime.parse(s['updated_at']) }.last
                              end
            end

            values = []
            values += [item[:user].id,
                       item[:data].created_at,
                       item[:data].created_at.strftime('%Y-%m-%d'),
                       first_enrollment?(full_enrollment),
                       item[:user].created_at.strftime('%Y-%m-%d'),
                       item[:user].language,
                       item[:user].affiliated,
                       item[:user].born_at,
                       item[:age],
                       item[:age_group]]

            unless privacy_flag
              values += [item[:user].first_name,
                         item[:user].last_name,
                         item[:user].email]
            end

            if extended_flag
              values += [metrics[:user_course_country],
                         metrics[:device_usage][:state],
                         metrics[:device_usage][:web],
                         metrics[:device_usage][:mobile],
                         clustering_metric_value(clustering_metrics, user.id, :sessions),
                         clustering_metric_value(clustering_metrics, user.id, :average_session_duration),
                         clustering_metric_value(clustering_metrics, user.id, :total_session_duration),
                         clustering_metric_value(clustering_metrics, user.id, :forum_activity),
                         clustering_metric_value(clustering_metrics, user.id, :textual_forum_contribution),
                         clustering_metric_value(clustering_metrics, user.id, :forum_observation),
                         clustering_metric_value(clustering_metrics, user.id, :item_discovery),
                         clustering_metric_value(clustering_metrics, user.id, :video_discovery),
                         clustering_metric_value(clustering_metrics, user.id, :quiz_discovery),
                         clustering_metric_value(clustering_metrics, user.id, :video_player_activity),
                         clustering_metric_value(clustering_metrics, user.id, :download_activity),
                         clustering_metric_value(clustering_metrics, user.id, :course_performance),
                         clustering_metric_value(clustering_metrics, user.id, :quiz_performance),
                         clustering_metric_value(clustering_metrics, user.id, :ungraded_quiz_performance),
                         clustering_metric_value(clustering_metrics, user.id, :graded_quiz_performance),
                         clustering_metric_value(clustering_metrics, user.id, :main_quiz_performance),
                         clustering_metric_value(clustering_metrics, user.id, :bonus_quiz_performance),
                         metrics[:course_activity]
                         # metrics[:question_response_time]
              ]
            end

            values += [(item[:data].created_at - course.start_date).to_i,
                       *item[:profile].fields.map{|f|f.value},
                       item[:stat_pinboard].questions,
                       item[:stat_pinboard].answers,
                       item[:stat_pinboard].comments_on_answers,
                       item[:stat_pinboard].comments_on_questions,
                       item[:stat_pinboard].questions + item[:stat_pinboard].answers + item[:stat_pinboard].comments_on_answers + item[:stat_pinboard].comments_on_questions,
                       item[:data].points[:achieved].present? ? item[:data].points[:achieved] : '',
                       item[:data].points[:percentage].present? ? item[:data].points[:percentage] : '',
                       item[:data].certificates[:confirmation_of_participation].present? ? item[:data].certificates[:confirmation_of_participation] : '-99',
                       item[:data].certificates[:record_of_achievement].present? ? item[:data].certificates[:record_of_achievement] : '-99',
                       item[:data].certificates[:certificate].present? ? item[:data].certificates[:certificate] : '-99',
                       item[:data].completed.present? ? item[:data].completed : '-99',
                       item[:data].deleted.present? ? item[:data].deleted : '-99',
                       item[:data].quantile.present? ? item[:data].quantile : '-99',
                       item[:data].quantile.present? ? calculate_top_performance(item[:data].quantile) : '-99',
                       item[:data].visits[:visited].present? ? item[:data].visits[:visited] : '',
                       item[:data].visits[:percentage].present? ? item[:data].visits[:percentage] : '']

            if course_ids.length == 1
              values += [*item[:cp].sections.map{ |s| s.visits_stats.user_percentage },
                         *item[:cp].sections.map{ |s| s.total_graded_points }]
            end

            values += [course.course_code]

            csv << values
            csv.flush
          rescue => e
            Sidekiq.logger.error e.inspect
            e.backtrace.each { |line| Sidekiq.logger.error line }
          end
        end

        pager += 1
        break if enrollments.total_pages == 0 || enrollments.current_page >= enrollments.total_pages
      end
      Acfs.run
    end

    return file
  ensure
    file.close
  end

  private

  def update_progress(job_id, enrollments, enrollment_index, courses_count, courses_index)
    job = Job.find(job_id)

    # progress of finished enrollment pages
    enrollment_progress_page = (enrollments.current_page - 1) / enrollments.total_pages.to_f

    # progress of one enrollment page
    enrollment_progress_by_page = 1 / enrollments.total_pages.to_f

    # progress of current enrollment
    enrollment_progress_current = enrollment_index / enrollments.size.to_f

    # progress of finished enrollment pages + current enrollment page progress
    enrollment_progress = enrollment_progress_page + (enrollment_progress_current * enrollment_progress_by_page)

    # progress of finished courses
    courses_progress = (courses_index - 1) / courses_count.to_f

    # progress of one course
    course_progress_by_index = 1 / courses_count.to_f

    # progress of finished courses + progress of current course by finished enrollments
    total_progress = courses_progress + (course_progress_by_index * enrollment_progress)

    job.progress = total_progress * 100
    job.save!
  end

  def age_group_from_age(age)
    age = age.to_i
    if age < 20
      '0+'
    elsif age < 30
      '20+'
    elsif age < 40
      '30+'
    elsif age < 50
      '40+'
    elsif age < 60
      '50+'
    elsif age < 70
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
  rescue => e
    Sidekiq.logger.error e.inspect
    0
  end

  def fetch_clustering_metrics(course_id, user_id = nil)
    clustering_metrics =
      %w(sessions
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
      )
    result = Lanalytics::Clustering::Dimensions.query(course_id, clustering_metrics, user_id ? [user_id] : nil)
    result.map { |x| [x['user_uuid'], x.except('user_uuid')] }.to_h.with_indifferent_access
  rescue => e
    Sidekiq.logger.error e.inspect
    {}
  end

  def clustering_metric_value(clustering_metrics, user_uuid, metric)
    value = clustering_metrics[user_uuid][metric] rescue nil
    value.present? ? value : '-99'
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

  def first_enrollment? (enrollment)
    all_enrollments = Xikolo.api(:course).value!.rel(:enrollments).get(
      user_id: enrollment.user_id,
      deleted: true,
      per_page: 500
    ).value!

    all_enrollments.none? { |e| DateTime.parse(e['created_at']) < enrollment.created_at }
  end

end
