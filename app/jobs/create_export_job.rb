require 'tempfile'
require 'csv'
require 'zipruby'

class CreateExportJob< ActiveJob::Base
  queue_as :default

  def perform (job_id, password, user_id, task_scope, privacy_flag)

  end

  private

  def create_report(*p)
  end

  def rename_and_zip (csv_name, filename, password = nil, additional_files = [])
    new_file_name = csv_name
    zipname = csv_name + ".zip"
    File.rename(filename, new_file_name)
    puts "*****"
    puts additional_files
    excel_name = get_tempdir.to_s + '/CourseExport_' + course.course_code.to_s + '_' + DateTime.now.strftime('%Y-%m-%d') + '.csv'

    ::ZipRuby::Archive.open(zipname, ::ZipRuby::CREATE) do |ar|
      ar.add_file(new_file_name)

      if additional_files
        additional_files.each do |additional_file|
          File.rename(additional_file.path, "test.xlsx")
          puts additional_file
        arr.add_file(additional_file.path)
      end
      unless password.nil? or password.empty?
        ar.encrypt(password)
      end
    end
    zipname
    end
    end


  def create_file (job_id, csv_name, temp_report, password, user_id, course_id=nil, additional_files )

    begin
      zipped_file_path =  rename_and_zip(csv_name, temp_report.path, password, additional_files)
      file = File.open(zipped_file_path, 'rb')
      uploader = FileUploader.new
      file_expire_date = 1.days.from_now
      file_uuid = uploader.upload(Xikolo::File::UploadedFile,
                                  file,
                                  %w(reports),
                                  nil,
                                  user_id,
                                  false,
                                  course_id,
                                  file_expire_date
      )

      job = Job.find(job_id)
      job.file_id = file_uuid
      job.user_id = user_id
      job.file_expire_date = file_expire_date
      job.status = 'done'
      job.progress = 100
      job.save
      notify(user_id, job.task_type, job.annotation, job.status)
      file.close
    rescue => error
      puts error.inspect
      job.status = 'failing'
      job.save
    ensure
      File.delete(file.path) if File.exist?(file.path)
      File.delete(csv_name) if File.exist?(csv_name)
    end
  end

  def find_and_save_job(job_id)
    job = Job.find(job_id)
    job.status = 'started'
    job.save
    job
  end

  def update_progress(objects, job_id, p)
    job = Job.find(job_id)
    progress_page = (objects.current_page-1) / objects.total_pages.to_f # watch the type casting
    progress_by_page = 1/objects.total_pages.to_f
    progress_current_item = p / objects.size.to_f
    total_progress = progress_page + (progress_current_item*progress_by_page)
    job.progress =total_progress*100
    job.save!
  end

  def get_tempdir
    Rails.root.join('tmp')
  end

  def notify(user_id, type, annotation, state)
    event = {
        key: 'reporting_finished',
        receiver_id:user_id,
        payload: {
             type: type,
            annotation: annotation,
             state: state
        }
    }

    Msgr.publish(event, to: 'xikolo.notification.platform_notify')
  end
end
