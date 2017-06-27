require 'net/http'

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

  def zip_files(files, password, target)
    password = password.present? ? "--password #{password}" : ''
    system "zip #{password} #{target} #{files.join(' ')}"

    raise "Zipping files failed: #{$?}" if $?.exitstatus > 0
  end

  def upload_file(file, expire_date, user_id, scope)
    record = Xikolo::File::UploadedFile.new(
      name: File.basename(file.path),
      path: File.join('reports', File.basename(file.path)),
      description: nil,
      user_id: user_id,
      mime_type: 'application/zip' # this is hardcoded for now
    )
    record.course_id = scope if scope
    record.expire_at = expire_date if expire_date

    return nil unless record.save

    return nil unless upload_file_contents(file, record.id)

    record.id
  end

  BOUNDARY = 'RubyMultipartPostFDSFAKLdslfds'
  def upload_file_contents(file, id)
    file.rewind

    uri = URI.parse("#{Xikolo::Common::API.services[:file]}/uploaded_files/#{id}/upload")

    post_body = []
    post_body << "--#{BOUNDARY}\r\n"
    post_body << "Content-Disposition: form-data; name=\"datafile\"\r\n"
    post_body << "Content-Type: text/plain\r\n"
    post_body << "\r\n"
    post_body << file.read
    post_body << "\r\n--#{BOUNDARY}--\r\n"

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = post_body.join
    request['Content-Type'] = "multipart/form-data, boundary=#{BOUNDARY}"

    response = http.request(request)
    response.kind_of? Net::HTTPSuccess
  end
end
