require 'fileutils'

class CreateReportJob < ActiveJob::Base
  queue_as :default

  def perform(job_id, report_params = {})
    job = Job.start(job_id)

    begin
      zip_password = report_params.delete(:zip_password)

      job.in_tmp_directory do
        # Let the reporter do its work (i.e. generate a bunch of files)
        report = job.generate!(report_params)

        # Zip up the generated files
        zip_file = "#{File.basename(report.files.first, '.*')}.zip"
        zip_files(report.files, zip_password, zip_file)

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
    expire_date = 1.days.from_now

    job.finish_with(
      file_id: upload_file(path, expire_date, job.user_id, job.task_scope),
      file_expire_date: expire_date
    )
  end

  def zip_files(files, password, target)
    password = password.present? ? "--password #{password}" : ''
    system "zip #{password} #{target} #{files.join(' ')}"

    raise "Zipping files failed: #{$?}" if $?.exitstatus > 0
  end

  def upload_file(file_path, expire_date, user_id, scope)
    file_name = File.basename(file_path)
    file_attrs = {
      name: file_name,
      path: File.join('reports', file_name),
      size: File.size(file_name),
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
