class CreateCombinedCourseExportJob < CreateCourseExportJob
  queue_as :default

  def perform(job_id, password, user_id, classifier_id, privacy_flag, extended_flag)
    job = find_and_save_job(job_id)

    begin
      classifier = Xikolo::Course::Classifier.find(classifier_id)
      courses = Xikolo::Course::Course.where(cat_id: classifier_id)
      Acfs.run
      course_ids = courses.map { |course| course.id }
      job.annotation = classifier.cluster.underscore + '_' + classifier.title.underscore
      job.save
      temp_report = create_report(job_id, course_ids, privacy_flag, extended_flag)
      csv_name = get_tempdir.to_s + '/CombinedCourseExport_' + classifier.cluster.underscore + '_' + classifier.title.underscore + '_' + DateTime.now.strftime('%Y-%m-%d') + '.csv'
      create_file(job_id, csv_name, temp_report.path, false, false, password, user_id, nil, nil)
    rescue => error
      Sidekiq.logger.error error.inspect
      job.status = 'failing'
      job.save
      File.delete(temp_report) if File.exist?(temp_report)
    end
  end

end
