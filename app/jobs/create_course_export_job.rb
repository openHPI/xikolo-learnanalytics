class CreateCourseExportJob < CreateExportJob
  queue_as :default

  def perform (job_id, password, user_id, course_id, privacy_flag, extended_flag)
    job = find_and_save_job (job_id)

    begin
      course = Xikolo::Course::Course.find(course_id)
      Acfs.run
      job.annotation = course.course_code.to_s
      job.save
      temp_report, temp_excel_report = create_report(job_id, course_id, privacy_flag, extended_flag)
      csv_name = get_tempdir.to_s + '/CourseExport_' + course.course_code.to_s + '_' + DateTime.now.strftime('%Y-%m-%d') + '.csv'
      excel_name = get_tempdir.to_s + '/CourseExport_' + course.course_code.to_s + '_' + DateTime.now.strftime('%Y-%m-%d') + '.xlsx'
      additional_files = []
      create_file(job_id, csv_name, temp_report.path, excel_name, temp_excel_report.path, password, user_id, course_id, additional_files)
    rescue => error
      puts error.inspect
      job.status = 'failing'
      job.save
    end
  end

  private

  def create_report (job_id, course_id, privacy_flag = false, extended_flag = false)
    page_size = 50
    course = Xikolo::Course::Course.find(course_id)
    Acfs.run
    birth_compare_date = course.start_date.present? ? course.start_date : DateTime.now
    pager = 1
    file = Tempfile.open(job_id.to_s, get_tempdir)
    csv = CSV.new(file)
    excel_tmp_file =  Tempfile.new('excel_course_export')
    headers = []
    course_info = []
    loop do
      enrollments = Xikolo::Course::Enrollment.where(course_id: course_id, page: pager, per_page: page_size, deleted: true)
      Acfs.run
      if enrollments.current_page == 1
        if enrollments.size > 0
          enrolled_user = Xikolo::Account::User.find enrollments.first.user_id if enrollments.first.present?
          Acfs.run
          presenter = Account::ProfilePresenter.new enrolled_user
          cp = Course::ProgressPresenter.build enrolled_user, course
          Acfs.run

          headers += ['User ID',
                      'Enrollment Role',
                      'Enrollment Date',
                      'Enrollment Day',
                      'Language',
                      'Affiliated',
                      'Birthdate',
                      'Age'
          ]
          headers += ['First Name',
                      'Last Name',
                      'Email'
          ] unless privacy_flag
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
                      'Course Activity',
                      'Question Response Time',
          ] if extended_flag
          headers += ['Enrollment Delta in Days',
                      *presenter.fields.map{|f|f.name.titleize},
                      'Questions',
                      'Answers',
                      'Comments on Answers',
                      'Comments on Questions',
                      'Points Achived',
                      'Points Percentage',
                      'Confirmation of Participation',
                      'Record of Achievement',
                      'Certificate',
                      'Completed',
                      'Deleted',
                      'Quantile',
                      'Top Performance',
                      *cp.sections.map{|f|f.title.titleize + ' Percentage'},
                      *cp.sections.map{|f|f.title.titleize + ' Points'},
                      'Course Code'
          ]
          csv << headers
        end
      end
      p = 0
      enrollments.each do |enrollment|
        p += 1
        item = {}
        begin
          update_progress(enrollments, job_id, p)
          user = Xikolo::Account::User.find enrollment.user_id
          #fullenrollment = ::API[:course].rel(:enrollments).get(user_id: user.id, course_id: enrollment.course_id, learning_evaluation: "true")
          fullenrollment = Xikolo::Course::Enrollment.find_by(user_id: enrollment.user_id, course_id: enrollment.course_id, learning_evaluation: 'true')
          Acfs.run

          item[:user] = UserPresenter.create user
          item[:profile] = Account::ProfilePresenter.new user
          item[:data] = fullenrollment
          item[:stat_pinboard] = Xikolo::Pinboard::Statistic.find course.id, params: {user_id: user.id}
          #for user and profile presenter
          item[:cp] = Course::ProgressPresenter.build user, course
          Acfs.run

          item[:age] = item[:user].born_at.present? ? ((birth_compare_date - item[:user].born_at)/ 365).to_i : "-99"

          item[:top_performance] = caluculate_top_performance(fullenrollment.quantile)

          if extended_flag
            metrics = ActiveSupport::HashWithIndifferentAccess.new

            metrics[:device_usage] = fetch_device_usage(course_id, user.id)

            course_activity = fetch_metric('CourseActivity', course_id, user.id)
            metrics[:course_activity] = course_activity.present? && course_activity[:count].present? ? course_activity[:count].to_s : "-99"

            question_response_time = fetch_metric('QuestionResponseTime', course_id, user.id)
            metrics[:question_response_time] = question_response_time.present? && question_response_time[:average].present? ? question_response_time[:average].to_s : "-99"

            user_course_country = fetch_metric('UserCourseCountry', course_id, user.id, :unescaped_query)
            metrics[:user_course_country] = user_course_country.present? ? user_course_country : "zz"

            clustering_metrics = fetch_clustering_metrics(course_id, user.id)
            metrics.merge! clustering_metrics
          end

          values = []
          values += [item[:user].id,
                     'student',
                     item[:data].created_at,
                     item[:data].created_at.strftime('%Y-%m-%d'),
                     item[:user].language,
                     item[:user].affiliated,
                     item[:user].born_at,
                     item[:age]
          ]
          values += [item[:user].first_name,
                     item[:user].last_name,
                     item[:user].email
          ] unless privacy_flag
          values += [metrics[:user_course_country],
                     metrics[:device_usage][:state],
                     metrics[:device_usage][:web],
                     metrics[:device_usage][:mobile],
                     metrics[:sessions],
                     metrics[:average_session_duration],
                     metrics[:total_session_duration],
                     metrics[:forum_activity],
                     metrics[:textual_forum_contribution],
                     metrics[:forum_observation],
                     metrics[:item_discovery],
                     metrics[:video_discovery],
                     metrics[:quiz_discovery],
                     metrics[:video_player_activity],
                     metrics[:download_activity],
                     metrics[:course_performance],
                     metrics[:quiz_performance],
                     metrics[:ungraded_quiz_performance],
                     metrics[:graded_quiz_performance],
                     metrics[:main_quiz_performance],
                     metrics[:bonus_quiz_performance],
                     metrics[:course_activity],
                     metrics[:question_response_time]
          ] if extended_flag
          values += [(item[:data].created_at - course.start_date).to_i,
                     *item[:profile].fields.map{|f|f.value},
                     item[:stat_pinboard].questions,
                     item[:stat_pinboard].answers,
                     item[:stat_pinboard].comments_on_answers,
                     item[:stat_pinboard].comments_on_questions,
                     item[:data].points[:achieved].present? ? item[:data].points[:achieved] : '',
                     item[:data].points[:percentage].present? ? item[:data].points[:percentage] : '',
                     item[:data].certificates[:confirmation_of_participation].present? ? item[:data].certificates[:confirmation_of_participation] : '-99',
                     item[:data].certificates[:record_of_achievement].present? ? item[:data].certificates[:record_of_achievement] : '-99',
                     item[:data].certificates[:certificate].present? ? item[:data].certificates[:certificate] : '-99',
                     item[:data].completed.present? ? item[:data].completed : '',
                     item[:data].deleted.present? ? item[:data].deleted : '',
                     item[:data].quantile.present? ? item[:data].quantile : '',
                     item[:top_performance],
                     *item[:cp].sections.map{|s|s.visits_stats.user_percentage},
                     *item[:cp].sections.map{|s|s.main_exercise_stats.graded_points if s.main_exercise_stats.available? },
                     course.course_code
          ]
          csv << values
          course_info << values
        rescue Exception => e
          puts e.message
        end
      end
      pager = pager+1
      break if enrollments.total_pages == 0
      break if (enrollments.current_page >= enrollments.total_pages)
    end


    file.close
    Acfs.run

    excel_file = excel_attachment('CourseExport', excel_tmp_file, headers, course_info)
    excel_file.close
    return file, excel_file
  end

  def fetch_device_usage (course_id, user_id)
    device_usage = fetch_metric('DeviceUsage', course_id, user_id)

    result = {}

    unless device_usage == 0
      result[:state] = device_usage[:behavior][:state]
      device_usage[:behavior][:usage].each do |usage|
        result[usage[:category].to_sym] = usage[:total_activity].to_s
      end
    else
      result[:state] = "unknown"
    end
    result[:mobile] = "0" unless result.key? :mobile
    result[:web] = "0" unless result.key? :web

    return result
  end

  def fetch_metric (metric, course_id, user_id, exec = :query)
    begin
      metric = "Lanalytics::Metric::#{metric}".constantize
      result = metric.public_send(exec,
          user_id,
          course_id,
          nil, nil, nil, nil, nil
      )
    rescue => error
      puts error.inspect
      result = 0
    end
  end

  def fetch_clustering_metrics (course_id, user_id)
    clustering_metrics = [
        'sessions',
          'average_session_duration',
          'total_session_duration',
        'forum_activity',
          'textual_forum_contribution',
          'forum_observation',
        'item_discovery',
         'video_discovery',
         'quiz_discovery',
        'video_player_activity',
        'download_activity',
        'course_performance',
        'quiz_performance',
          'ungraded_quiz_performance',
         'graded_quiz_performance',
         'main_quiz_performance',
         'bonus_quiz_performance'
    ]
    result = Lanalytics::Clustering::Dimensions.query(course_id, clustering_metrics, [user_id]).first.with_indifferent_access
    result.each { |k, v| result[k] = -99 if v.nil? }
    return result
  rescue => error
    puts error.inspect
    clustering_metrics.each { |metric| result[metric.to_sym] = -99 }
    return result
  end

  def caluculate_top_performance (quantile)
    return "-99" unless quantile
    top_percentage = (1 - quantile.to_f).round(2)
    if top_percentage <= 0.05
      return "Top5"
    elsif top_percentage <= 0.1
      return "Top10"
    elsif top_percentage <= 0.2
      return "Top20"
    end
  end

end