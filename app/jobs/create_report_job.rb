require 'fileutils'

class CreateReportJob < ActiveJob::Base
  queue_as :default

  def perform(job_id, options = {})
    job = ReportJob.start(job_id)

    begin
      zip_password = options.delete(:zip_password)

      job.with_tmp_directory do
        # Let the reporter do its work (i.e. generate a bunch of files)
        report = job.generate!(options)

        # Zip up the generated files
        zip_file = report.files.zip(zip_password)

        # ...and finally send them to the file service
        publish_file job, zip_file
      end
    rescue => error
      trace = "#{error.message}\n#{error.backtrace.join("\n")}"
      Sidekiq.logger.error trace
      job.fail_with trace
    end
  end

  private

  def publish_file(job, path)
    expire_date = 7.days.from_now

    job.finish_with(
      file_id: upload_file(path, expire_date, job.user_id, job.task_scope),
      file_expire_date: expire_date
    )
  end

  def upload_file(file_path, expire_date, user_id, scope)
    file_name = File.basename(file_path)
    file_attrs = {
      name: file_name,
      path: File.join('reports', file_name),
      size: file_path.size,
      description: nil,
      user_id: user_id,
      mime_type: 'application/zip'
    }
    file_attrs[:course_id] = scope if scope
    file_attrs[:expire_at] = expire_date if expire_date

    record = Xikolo.api(:file).value!.rel(:uploaded_files).post(file_attrs).value!

    target_dir = Xikolo.config.data_dir.join('reports')
    FileUtils.mkpath target_dir
    FileUtils.move file_path, target_dir.join(file_name)

    record['id']
  end
end
