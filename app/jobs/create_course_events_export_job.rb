class CreateCourseEventsExportJob < CreateExportJob
  queue_as :default

  def perform(job_id, password, user_id, course_id, privacy_flag)
    job = find_and_save_job (job_id)

    begin
      #course_id = 'c1556425-5449-4b05-97b3-42b38a39f6c5' #manual overwrite
      course = Xikolo::Course::Course.find(course_id)
      Acfs.run
      job.annotation = course.course_code.to_s
      job.save
      temp_report, temp_excel_report = create_report(job_id, course_id, privacy_flag)
      csv_name = "#{get_tempdir}/CourseEventsExport_#{course_id}_#{DateTime.now.strftime('%Y-%m-%d')}.csv"
      excel_name = "#{get_tempdir}/CourseEventsExport_#{course_id}_#{DateTime.now.strftime('%Y-%m-%d')}.xlsx"
      additional_files = []
      create_file(job_id, csv_name, temp_report.path, excel_name, temp_excel_report.path, password, user_id, course_id, additional_files)
    rescue => error
      Sidekiq.logger.error error.inspect
      job.status = 'failing'
      job.save
    end
  end

  private

  def create_report(job_id, course_id, privacy_flag)
    file = Tempfile.open(job_id.to_s, get_tempdir)
    excel_tmp_file =  Tempfile.new('excel_course_export')
    headers = []
    courseevent_info = []
    @filepath = File.absolute_path(file)

    course = Xikolo::Course::Course.find(course_id)
    items = ActiveSupport::HashWithIndifferentAccess.new
    sections = ActiveSupport::HashWithIndifferentAccess.new
    #we may need to include deleted if there is usage data for those
    Xikolo::Course::Section.each_item(course_id: course_id) do |section|
      sections[section.id] = section
    end
    Xikolo::Course::Item.each_item(course_id: course_id) do |item|
     items[item.id] = item
    end
    Acfs.run
    puts 'after acfs'

    CSV.open(@filepath, 'wb') do |csv|
      headers += ['Course ID', 'Verb', 'User', 'Timestamp', 'Resource', 'Action', 'Typ', 'Title', 'Section' ]
      csv << headers
      Sidekiq.logger.debug 'Writing export to '+ @filepath + " \n" + 'with headers ' + headers.to_s
      i = 0
      if course.start_date.present? and course.end_date.present?
        logger.debug 'get data'
        get_all course, csv, courseevent_info, items, sections
      end
    end
    file.close
    Acfs.run
    excel_file = excel_attachment('CourseEventsExport', excel_tmp_file, headers, courseevent_info)
    excel_file.close
    return file, excel_file
  end

  def update_job_progress(job_id, percent)
    job = Job.find(job_id)
    job.progress = percent
    job.save!
  end

  def get_all(course, csv, courseevent_info, items, sections)
    page = 1
    scroll_id = nil
    loop do
      paged = do_query page, course, scroll_id
      paged[:data].each do |item|
        id = item['resource']
        if item['verb'] == 'VISITED'
          begin
            item['type'] = items[id].content_type
            # this is a course item
            item['title'] = items[id].title
            item['section'] = sections[items[id].section_id].title
            item['action'] = item['verb'] + ' ' + item['title'] + ' ' + item['type'] + ' ' + id #custom action name
          rescue
            item['type'] = ''
            item['title'] = ''
            item['section'] = ''
          end
        else
          item['type'] = ''
          item['title'] = ''
          item['section'] = ''
        end
        csv << item.values
        courseevent_info << item.values
      end
      scroll_id = paged[:scroll_id]
      puts paged[:next]
      puts paged[:next] == true
      break unless paged[:next] == true
      page = page + 1
    end
  end

  def do_query(page, course, scroll_id)
    Lanalytics::Metric::CourseEvents.query(
        nil,
        course.id,
        course.start_date.iso8601,
        course.end_date.iso8601,
        page,
        nil,
        scroll_id)
  end
end
