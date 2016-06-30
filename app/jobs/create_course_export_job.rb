class CreateCourseExportJob < CreateExportJob
  queue_as :default

  def perform (job_id, password, user_id, course_id, privacy_flag)
    job = find_and_save_job (job_id)

    begin
    course = Xikolo::Course::Course.find(course_id)
    Acfs.run
    job.annotation = course.course_code.to_s
    job.save
    temp_report = create_report(job_id, course_id, privacy_flag)
    csv_name = get_tempdir.to_s + '/CourseExport_' + course.course_code.to_s + '_' + DateTime.now.strftime('%Y-%m-%d') + '.csv'
    additional_files = []
    create_file(job_id, csv_name, temp_report, password, user_id, course_id, additional_files)
    rescue => error
      puts error.inspect
      job.status = 'failing'
      job.save
    end
  end

  private

  def create_report (job_id, course_id, privacy_flag=false)
    page_size = 50
    course = Xikolo::Course::Course.find(course_id)
    Acfs.run
    pager = 1
    file = Tempfile.open(job_id.to_s, get_tempdir)
    csv = CSV.new(file)
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

          headers = []
          headers += ['User ID',
                      'Enrollment role',
                      'Enrollment date',
                      'Enrollment_day'
          ]
          headers += ['First Name',
                      'Last name',
                      'Email'
          ] unless privacy_flag
          headers += ['Language',
                      'Affiliated',
                      'BirthDate',
                      'TopCountry',
                      'DeviceUsage',
                      'WebUsage',
                      'MobileUsage',
                      'Sessions',
                      'AvgSessionDuration',
                      'TotalSessionDuration',
                      'ForumActivity',
                      'ForumTextualContribution',
                      'ForumObservation',
                      'ItemDiscovery',
                      'VideoDiscovery',
                      'QuizDiscovery',
                      'VideoPlayerActivity',
                      'DownloadActivity',
                      'CoursePerformance',
                      'QuizPerformance (total)',
                      'QuizPerformance (avg points percentage)',
                      'QuizPerformance (avg attempts)',
                      'QuizPerformance (avg points percentage first attempt)',
                      'UngradedQuizPerformance',
                      'GradedQuizPerformance',
                      'MainQuizPerformance',
                      'BonusQuizPerformance',
                      'CourseActivity',
                      'QuestionResponseTime (avg)',
                      'EnrollmentDeltaInDays',
                      *presenter.fields.map{|f|f.name},
                      'questions',
                      'answers',
                      'comments_on_answers',
                      'comments_on_questions',
                      'points.achived',
                      'points.percentage',
                      'certificates.cop',
                      'certificates.roa',
                      'certificates.paidcertificate',
                      'completed',
                      'deleted',
                      'quantile',
                      *cp.sections.map{|f|f.title + '_percentage'},
                      *cp.sections.map{|f|f.title + '_points'},
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

          item[:user] =  UserPresenter.create user
          item[:profile] = Account::ProfilePresenter.new user
          item[:data] =  fullenrollment
          item[:stat_pinboard] = Xikolo::Pinboard::Statistic.find course.id, params: {user_id: user.id}
          #for user and profile presenter
          item[:cp] = Course::ProgressPresenter.build user, course
          Acfs.run

          item[:device_usage] = fetch_device_usage(course_id, item[:user].id)
          item[:quiz_performance] = fetch_quiz_performance(course_id, user.id)

          values = []
          values += [item[:user].id,
                     'student',
                     item[:data].created_at,
                     item[:data].created_at.strftime('%Y-%m-%d')
          ]
          values += [item[:user].first_name,
                     item[:user].last_name,
                     item[:user].email
          ] unless privacy_flag
          values += [item[:user].language,
                     item[:user].affiliated,
                     item[:user].born_at,
                     fetch_top_country(course_id, user.id),
                     item[:device_usage][:state],
                     item[:device_usage][:web],
                     item[:device_usage][:mobile],
                     fetch_metric('Sessions', course_id, user.id),
                     fetch_metric('AvgSessionDuration', course_id, user.id),
                     fetch_metric('TotalSessionDuration', course_id, user.id),
                     fetch_metric('ForumActivity', course_id, user.id),
                     fetch_metric('ForumTextualContribution', course_id, user.id),
                     fetch_metric('ForumObservation', course_id, user.id),
                     fetch_metric('ItemDiscovery', course_id, user.id),
                     fetch_metric('VideoDiscovery', course_id, user.id),
                     fetch_metric('QuizDiscovery', course_id, user.id),
                     fetch_metric('VideoPlayerActivity', course_id, user.id),
                     fetch_metric('DownloadActivity', course_id, user.id),
                     fetch_metric('CoursePerformance', course_id, user.id),
                     item[:quiz_performance][:total],
                     item[:quiz_performance][:average_points_percentage],
                     item[:quiz_performance][:avg_attempts],
                     item[:quiz_performance][:average_points_percentage_first_attempt],
                     fetch_metric('UngradedQuizPerformance', course_id, user.id),
                     fetch_metric('GradedQuizPerformance', course_id, user.id),
                     fetch_metric('MainQuizPerformance', course_id, user.id),
                     fetch_metric('BonusQuizPerformance', course_id, user.id),
                     fetch_metric('CourseActivity', course_id, user.id)[:count],
                     fetch_metric('QuestionResponseTime', course_id, user.id)[:average].to_i,
                     (item[:data].created_at - course.start_date).to_i,
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
                     *item[:cp].sections.map{|s|s.visits_stats.user_percentage},
                     *item[:cp].sections.map{|s|s.main_exercise_stats.graded_points if s.main_exercise_stats.available? }
          ]
          csv << values
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
    file
  end

  def fetch_top_country (course_id, user_id)
    begin
      top_country = API[:learnanalytics].rel(:query).get(
          metric: 'UserCourseCountry',
          course_id: course_id,
          start_time: nil,
          end_date: nil,
          resource_id: user_id).value!
    rescue => error
      puts error.inspect
      top_country = ''
    end
  end

  def fetch_device_usage (course_id, user_id)
    result = {}
    begin
      device_usage = API[:learnanalytics].rel(:query).get(
          metric: 'DeviceUsage',
          user_id: user_id,
          course_id: course_id,
          start_time: nil,
          end_date: nil,
          resource_id: nil).value!
      result[:state] = device_usage[:behavior][:state]
      device_usage[:behavior][:usage].each do |usage|
        result[usage[:category].to_sym] = usage[:total_activity]
      end
    rescue => error
      puts error.inspect
      result = {[:state] => "unknown"}
    end
    result[:mobile] = 0 unless result.key? :mobile
    result[:web] = 0 unless result.key? :web

    return result
  end


  def fetch_quiz_performance (course_id, user_id)
    begin
      result = API[:learnanalytics].rel(:query).get(
          metric: 'QuizPerformance',
          course_id: course_id,
          start_time: nil,
          end_date: nil,
          resource_id: user_id).value!
    rescue => error
      puts error.inspect
      result = {
          total: 0,
          average_points_percentage: 0,
          avg_attempts: 0,
          average_points_percentage_first_attempt: 0
      }
    end
  end

  def fetch_metric (metric, course_id, user_id)
    begin
      result = API[:learnanalytics].rel(:query).get(
          metric: metric,
          user_id: user_id,
          course_id: course_id,
          start_time: nil,
          end_date: nil,
          resource_id: nil).value!
    rescue => error
      puts error.inspect
      result = 0
    end
  end

end


