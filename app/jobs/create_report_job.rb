require 'fileutils'
require 'xikolo/s3'

class CreateReportJob < ApplicationJob
  queue_as :default

  def perform(job_id)
    job = ReportJob.start(job_id)

    begin
      zip_password = job.options['zip_password']

      job.with_tmp_directory do
        # Let the reporter do its work (i.e. generate a bunch of files)
        report = job.generate!

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
    job.finish_with upload_file(path, job.id)
  rescue => error
    trace = "#{error.class.name}: #{error.message}\n#{error.backtrace.join("\n")}"
    job.fail_with("Report could not be stored:\n#{trace}")
  end

  def upload_file(file_path, job_id)
    # which bucket should we use:
    bucket = Xikolo::S3.bucket_for(:reports)
    # upload report:
    object = bucket.put_object(
      key: 'reports/' + job_id + '/' + File.basename(file_path),
      body: open(file_path),
      acl: 'private',
      content_type: 'application/zip',
      metadata: {
        'job-id' => job_id
      }
    )

    # we expect the S3 object to be deleted after 7 days
    # lets generate a presigned-download url for this durtain and
    # define this as file expire date:
    valid_duration = 604800 # one week
    {
      file_expire_date: valid_duration.seconds.from_now,
      download_url: object.presigned_url(:get, expires_in: valid_duration)
    }
  end
end
