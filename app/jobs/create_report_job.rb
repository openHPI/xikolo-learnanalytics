class CreateReportJob < ActiveJob::Base
  queue_as :default

  def perform(job_id, report_params = {})
    job = Job.start(job_id)

    begin
      zip_password = report_params.delete(:zip_password)

      job.in_tmp_directory do |tmp_dir|
        # Let the reporter do its work (i.e. generate a bunch of files)
        report = job.generate!(report_params)

        # Zip up the generated files
        zip_file = tmp_dir.join("#{File.basename(report.files.first, '.*')}.zip")
        zip_files(report.files, zip_password, zip_file)

        # ...and finally send them to the file service
        publish_file job, zip_file
      end
    rescue => error
      Sidekiq.logger.error error.inspect
      job.fail
    end
  end

  private

  def publish_file(job, path)
    expire_date = 1.days.from_now

    File.open(path, 'rb') do |file|
      job.finish_with(
        file_id: upload_file(file, expire_date, job.user_id, job.task_scope),
        file_expire_date: expire_date
      )
    end
  end

  def zip_files(files, password, path)
    password = password.present? ? "--password #{password}" : ''
    system "zip #{password} #{path} #{files.join(' ')}"

    raise "Zipping files failed: #{$?}" if $?.exitstatus > 0
  end

  def upload_file(file, expire_date, user_id, scope)
    FileUploader.new.upload(
      Xikolo::File::UploadedFile,
      file,
      %w(reports),
      nil,
      user_id,
      false,
      scope,
      expire_date
    )
  end
end
