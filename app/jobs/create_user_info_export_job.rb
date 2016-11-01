class CreateUserInfoExportJob < CreateExportJob
  queue_as :default

  def perform (job_id, password, user_id, course_id = nil, privacy_flag, combined_enrollment_info_flag)
    job = find_and_save_job(job_id)
    begin
      temp_report, temp_excel_report = create_report(job_id, privacy_flag, combined_enrollment_info_flag)
      csv_name = get_tempdir.to_s + '/UserInfoExport_' + DateTime.now.strftime('%Y-%m-%d') + '.csv'
      excel_name = get_tempdir.to_s + '/UserInfoExport_' + DateTime.now.strftime('%Y-%m-%d') + '.xlsx'
      additional_files = []
      create_file(job_id, csv_name, temp_report.path, excel_name, temp_excel_report.path, password, user_id, course_id, additional_files)
    rescue => error
      Sidekiq.logger.error error.inspect
      job.status = 'failing' +  error.inspect
      job.save
      File.delete(temp_report) if File.exist?(temp_report)
      File.delete(temp_excel_report) if File.exist?(temp_excel_report)
    end
  end


  private

  def create_report(job_id, privacy_flag, combined_enrollment_info_flag=false, use_course_state = false)
    pager = 1
    file = Tempfile.open(job_id.to_s, get_tempdir)
    csv = CSV.new(file)
    @filepath = File.absolute_path(file)
    excel_tmp_file =  Tempfile.new('excel_user_export')
    headers = []
    user_info = []
    courses = []
    Xikolo::Course::Course.each_item(affiliated: 'true', public: 'true') do |item|
      courses << item
    end
    Acfs.run
    all_courses = {}

    courses.each do |c|
      all_courses[c.id] = c
    end

    #$stdout.print all_courses.inspect
    Sidekiq.logger.debug "Writing export to #{@filepath}"
    #csv << ["row", "of", "CSV", "data"]

    loop do
      begin
        users = Xikolo::Account::User.where(confirmed: true, page: pager, per_page: 500)
        Acfs.run
        if users.current_page == 1
          presenter = Account::ProfilePresenter.new users.first
          Acfs.run
          #write header
          unless privacy_flag
            headers += ['User ID',
                 'First Name',
                 'Last name',
                 'Email',
                 'Language',
                 'Affiliated',
                 'BirthDate',
                 'TopCountry',
                 'FirstEnrollment',
                 *presenter.fields.map{|f|f.name},
                 *courses.map{|c|c.course_code}
            ]
          else
            headers += ['User ID',
                  'Language',
                  'Affiliated',
                  'Created',
                  'BirthDate',
                  'TopCountry',
                  'FirstEnrollment',
                  *presenter.fields.map{|f|f.name},
                  *courses.map{|c|c.course_code}
            ]
          end
          csv << headers

        end
        p = 0
        tmp_holder = {}
        user_courses = {}
        enrollments = {}
        profiles = {}
        users.each do |user|
          p += 1
          update_progress(users, job_id, p)
          enrollments[user.id] = Xikolo::Course::Enrollment.where(user_id: user.id, learning_evaluation: 'true', deleted: 'true', per_page: 200)
          profiles[user.id] = Account::ProfilePresenter.new user
          user_courses[user.id] = {}
          user_courses[user.id].each do |course|
            user_courses[user.id][course.id] = ''
          end
          #$stdout.print user_courses.inspect
          Acfs.run
        end
        Acfs.run
        #iterate again
        users.each do |user|
          enrollments[user.id].each do |enrollment|
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
              user_courses[user.id][enrollment.course_id] = state
            else
              user_courses[user.id][enrollment.course_id] = enrollment.points ? enrollment.points[:percentage] : '-'
            end
          end
          if enrollments[user.id].count > 0
           course_id = enrollments[user.id].sort_by { |c| c.created_at }.first.course_id
           if course_id.present? && all_courses[course_id].present? && all_courses[course_id].course_code.present?
              first_enrollment = all_courses[course_id].course_code
            else
              first_enrollment = ''
            end

          else
            first_enrollment = ''
          end

          begin
            top_country =  Lanalytics::Metric::UserCourseCountry.query(
                user.id,
                nil,
                nil,
                nil,
                nil,
                nil,
                nil)
          rescue => error
            Sidekiq.logger.error error.inspect
            top_country = ''
          end
          values = []
          unless privacy_flag
            values += [user.id,
                   user.first_name,
                   user.last_name,
                   user.email,
                   user.language,
                   user.affiliated,
                   user.born_at,
                   top_country,
                   first_enrollment,
                   *profiles[user.id].fields.map{|f|f.value},
                   *courses.map{|c|user_courses[user.id][c.id].present? ? user_courses[user.id][c.id] : 'n'}
            ]
          else
            values += [user.id,
                   user.language,
                   user.affiliated,
                   user.created_at.strftime('%Y-%m-%d'),
                   user.born_at,
                   top_country,
                   first_enrollment,
                   *profiles[user.id].fields.map{|f|f.value},
                   *courses.map{|c|user_courses[user.id][c.id].present? ? user_courses[user.id][c.id] : 'n'}
            ]
          end
          csv << values
          user_info << values

        end

        Sidekiq.logger.debug "fetching page #{pager.to_s}"
        pager = pager+1
        break if (users.current_page >= users.total_pages)

      rescue Exception => error
        Sidekiq.logger.error error.message
      end
    end
      excel_file = excel_attachment('UserInfoExport', excel_tmp_file, headers, user_info)

      Acfs.run
      return file, excel_file

  ensure
    file.close
    excel_file.close
  end
end



