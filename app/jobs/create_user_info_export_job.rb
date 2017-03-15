class CreateUserInfoExportJob < CreateExportJob
  queue_as :default

  def perform (job_id, password, user_id, course_id = nil, privacy_flag, combined_enrollment_info_flag)
    job = find_and_save_job(job_id)
    begin
      temp_report = create_report(job_id, privacy_flag, combined_enrollment_info_flag)
      csv_name = get_tempdir.to_s + '/UserInfoExport_' + DateTime.now.strftime('%Y-%m-%d') + '.csv'
      create_file(job_id, csv_name, temp_report.path, false, false, password, user_id, course_id, nil)
    rescue => error
      Sidekiq.logger.error error.inspect
      job.status = 'failing' +  error.inspect
      job.save
      File.delete(temp_report) if File.exist?(temp_report)
    end
  end

  private

  def create_report(job_id, privacy_flag, combined_enrollment_info_flag = false, use_course_state = false)
    file = Tempfile.open(job_id.to_s, get_tempdir)
    csv = CSV.new(file)
    @filepath = File.absolute_path(file)

    courses = {}
    Xikolo::Course::Course.each_item(affiliated: 'true', public: 'true') do |course|
      courses[course.id] = course
    end
    Acfs.run

    Sidekiq.logger.debug "Writing export to #{@filepath}"

    pager = 1
    loop do
      begin
        users = Xikolo::Account::User.where(confirmed: true, page: pager, per_page: 500)
        Acfs.run

        if users.current_page == 1
          # write header

          presenter = Account::ProfilePresenter.new users.first
          Acfs.run

          headers = ['User ID']

          unless privacy_flag
            headers += ['First Name',
                        'Last name',
                        'Email']
          end

          headers += ['Language',
                      'Affiliated',
                      'Created',
                      'BirthDate',
                      'TopCountry',
                      'FirstEnrollment',
                      *presenter.fields.map { |f| f.name },
                      *courses.values.map { |c| c.course_code }]

          csv << headers
          csv.flush
        end

        users.each.with_index(1) do |user, index|
          update_progress(users, job_id, index)

          user_enrollments = Xikolo::Course::Enrollment.where(user_id: user.id, learning_evaluation: 'true', deleted: 'true', per_page: 200)
          user_profile = Account::ProfilePresenter.new user
          Acfs.run

          user_course_states = {}

          user_enrollments.each do |enrollment|
            if combined_enrollment_info_flag
              # '': not enrolled
              # e: enrolled
              # v: visited
              # p: achieved points
              # c: completed
              # r: RoA
              state = ''
              state = 'e' if enrollment.present?
              state = 'v' if enrollment.visits.present? and enrollment.visits[:visited].to_f > 0
              state = 'p' if enrollment.points.present? and enrollment.points[:percentage].to_f > 0
              state = 'c' if enrollment.completed
              state = 'r' if enrollment.certificates.present? and enrollment.certificates[:record_of_achievement]
              user_course_states[enrollment.course_id] = state
            else
              user_course_states[enrollment.course_id] = enrollment.points ? enrollment.points[:percentage] : '-'
            end
          end

          first_enrollment = ''
          if user_enrollments.count > 0
            course_id = user_enrollments.sort_by { |c| c.created_at }.first.course_id
            if course_id.present? && courses[course_id].present? && courses[course_id].course_code.present?
              first_enrollment = courses[course_id].course_code
            end
          end

          begin
            top_country = Lanalytics::Metric::UserCourseCountry.query(user.id, nil, nil, nil, nil, nil, nil)
          rescue => error
            Sidekiq.logger.error error.inspect
            top_country = ''
          end

          values = [user.id]

          unless privacy_flag
            values += [user.first_name,
                       user.last_name,
                       user.email]
          end

          values += [user.language,
                     user.affiliated,
                     user.created_at.strftime('%Y-%m-%d'),
                     user.born_at,
                     top_country,
                     first_enrollment,
                     *user_profile.fields.map { |f| f.value },
                     *courses.values.map { |c| user_course_states[c.id].present? ? user_course_states[c.id] : '-'}]

          csv << values
          csv.flush
        end

        Sidekiq.logger.debug "Fetching page #{pager.to_s}"
        pager = pager + 1
        break if (users.current_page >= users.total_pages)

      rescue Exception => error
        Sidekiq.logger.error error.message
      end

    end

    Acfs.run
    return file

  ensure
    file.close
  end

end
