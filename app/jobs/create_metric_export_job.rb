class CreateMetricExportJob < CreateExportJob
  queue_as :default

  def perform(job_id, password, user_id, scope, privacy_flag)
    job = find_and_save_job (job_id)

    begin
      temp_report = create_report(job_id, scope, privacy_flag)
      csv_name = get_tempdir.to_s + '/MetricExport_' + scope.to_s + '_' + DateTime.now.strftime('%Y-%m-%d') + '.csv'
      additional_files = []
      create_file(job_id, csv_name, temp_report, password, user_id, scope, additional_files)
    rescue => error
      puts error.inspect
      job.status = 'failing'
      job.save
    end
  end

  private

  def create_report(job_id, scope, privacy_flag)
    file = Tempfile.open(job_id.to_s, get_tempdir)
    @filepath = File.absolute_path(file)
    courses = []
    Xikolo::Course::Course.each_item(public: true) do |course|

      courses << course unless course.external_course_url.present?
    end
    Acfs.run

    CSV.open(@filepath, 'wb') do |csv|
      csv << ['Course Code', 'Enrollments', 'Metric' ]
      $stdout.print 'Writing export to '+ @filepath + " \n"
      i = 0
      courses.each do |course|
        course_stats = Xikolo::Course::Stat.find key: 'enrollments',
                                                 course_id: course.id,
                                                 start_date: course.start_date,
                                                 end_date: course.end_date
        Acfs.run
        i += 1
        tmp = []
        tmp << course.course_code
        tmp << course_stats.student_enrollments_at_end
        tmp << scope
        ## get metrics for each day from course start to course date
        day = course.start_date
        if course.start_date.present? and course.end_date.present?
          while day < course.end_date
             activity = ::API[:learnanalytics].rel(:query).get(
                 metric: scope,
                 course_id: course.id,
                 start_time: day.iso8601,
                 end_time: (day+24.hours).iso8601).value![:count]
             tmp << activity
             day += 24.hours
          end
          csv << tmp
          update_job_progress(job_id, i/courses.count*100 )
        end
     end
    end
    file.close
    Acfs.run
    file
  end

  def update_job_progress(job_id, percent)
    job = Job.find(job_id)
    job.progress = percent
    job.save!
  end
end
