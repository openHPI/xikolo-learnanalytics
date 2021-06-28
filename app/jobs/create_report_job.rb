# frozen_string_literal: true

require 'fileutils'
require 'lanalytics/s3'

class CreateReportJob < ApplicationJob
  queue_as do # Executed in the job context (so you can access self.arguments)
    job_id = arguments.first
    ReportJob.queue_name(job_id)
  end

  after_enqueue do |job|
    job_id = job.arguments.first
    ReportJob.queued(job_id)
  end

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
        job.finish_with upload_file(zip_file, job.id)
      end
    rescue => e
      trace =
        "#{e.class.name}: #{e.message}\n#{e.backtrace.join("\n")}"
      Sidekiq.logger.error trace
      ::Mnemosyne.attach_error(e)
      ::Sentry.capture_exception(e)
      job.fail_with e
    end
  end

  private

  def upload_file(file_path, job_id)
    # Where is our bucket?
    bucket = Lanalytics::S3.resource.bucket(
      Lanalytics.config.reports['s3_bucket'],
    )

    # Upload the generated report to S3
    object = File.open(file_path, 'rb') do |file|
      bucket.put_object(
        key: "reports/#{job_id}/#{File.basename(file_path)}",
        body: file,
        acl: 'private',
        content_type: 'application/zip',
        metadata: {'job-id' => job_id},
      )
    end

    # We expect the S3 object to be deleted after 7 days.
    # Let's generate a pre-signed download URL for this duration and remember
    # this as file expiry date.
    duration = 1.week

    {
      file_expire_date: duration.from_now,
      download_url: object.presigned_url(:get, expires_in: duration.to_i),
    }
  end
end
