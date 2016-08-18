class CreateCourseEventsExportJob < CreateExportJob
  queue_as :default

  def perform(job_id, password, user_id, scope, privacy_flag)
    job = find_and_save_job (job_id)

    begin
      #scope = 'c1556425-5449-4b05-97b3-42b38a39f6c5' #manual overwrite
      temp_report, temp_excel_report = create_report(job_id, scope, privacy_flag)
      csv_name = get_tempdir.to_s + '/CourseEventsExport_' + scope.to_s + '_' + DateTime.now.strftime('%Y-%m-%d') + '.csv'
      excel_name = get_tempdir.to_s + '/CourseEventsExport_' + scope.to_s + '_' + DateTime.now.strftime('%Y-%m-%d') + '.xlsx'

      additional_files = []
      create_file(job_id, csv_name, temp_report.path, excel_name, temp_excel_report.path, password, user_id, scope, additional_files)
    rescue => error
      puts error.inspect
      job.status = 'failing'
      job.save
      temp_report.close
      temp_report.unlink
      temp_excel_report.close
      temp_excel_report.unlink
    end
  end

  private

  def create_report(job_id, scope, privacy_flag)
    file = Tempfile.open(job_id.to_s, get_tempdir)
    excel_tmp_file =  Tempfile.new('excel_course_export')
    headers = []
    courseevent_info = []
    @filepath = File.absolute_path(file)

    course = Xikolo::Course::Course.find(scope)
    items = ActiveSupport::HashWithIndifferentAccess.new
    sections = ActiveSupport::HashWithIndifferentAccess.new
    #we may need to include deleted if there is usage ddata for those
    Xikolo::Course::Section.each_item(course_id: scope) do |section|
      sections[section.id] = section
    end
    Xikolo::Course::Item.each_item(course_id: scope) do |item|
     items[item.id] = item
    end
    Acfs.run
    puts 'after acfs'

    CSV.open(@filepath, 'wb') do |csv|
      headers += ['Course ID', 'Verb', 'User', 'Timestamp', 'Resource', 'Action', 'Typ', 'Title', 'Section' ]
      csv << headers
          $stdout.print 'Writing export to '+ @filepath + " \n" + "with headers " + headers.to_s
      i = 0
      if course.start_date.present? and course.end_date.present?
        puts 'get data'
        get_all course, csv, courseevent_info, items, sections
      end
    end
    Acfs.run
    excel_file = excel_attachment('CourseEventsExport', excel_tmp_file, headers, courseevent_info)
    return file, excel_file
  ensure
    file.close
    excel_file.close
    excel_tmp_file.close
  end

  def update_job_progress(job_id, percent)
    job = Job.find(job_id)
    job.progress = percent
    job.save!
  end

  def get_all(course, csv, courseevent_info, items, sections)
    page = 1
    loop do
      paged = do_query page, course
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
      puts paged[:next]
      puts paged[:next] == true
      break unless paged[:next] == true
      page = page + 1
    end
  end

  def do_query(page, course)
    Lanalytics::Metric::CourseEvents.query(
        nil,
        course.id,
        course.start_date.iso8601,
        course.end_date.iso8601,
        page,
        nil)
  end
end
