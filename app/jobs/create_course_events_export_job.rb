class CreateCourseEventsExportJob < CreateExportJob
  queue_as :default

  def perform(job_id, password, user_id, scope, privacy_flag)
    job = find_and_save_job (job_id)

    begin
      #scope = 'c1556425-5449-4b05-97b3-42b38a39f6c5' #manual overwrite
      temp_report = create_report(job_id, scope, privacy_flag)
      csv_name = get_tempdir.to_s + '/CourseEventsExport_' + scope.to_s + '_' + DateTime.now.strftime('%Y-%m-%d') + '.csv'
      additional_files = []
      create_file(job_id, csv_name, temp_report, password, user_id, scope, additional_files)
    rescue => error
      puts error.inspect
      job.status = 'failing'
      job.save
    end
  end

  private

  def create_report(job_id, scope, privacy_flag)
    file = Tempfile.open(job_id.to_s, get_tempdir)
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
      csv << ['Course ID', 'Verb', 'User', 'Timestamp', 'Resource', 'Action', 'Typ', 'Title', 'Section' ]
      $stdout.print 'Writing export to '+ @filepath + " \n"
      i = 0
      if course.start_date.present? and course.end_date.present?
        puts 'get data'
        get_all course, csv, items, sections
      end
    end
    file.close
    Acfs.run
    file
  end

  def update_job_progress(job_id, percent)
    job = Job.find(job_id)
    job.progress = percent
    job.save!
  end

  def get_all(course, csv, items, sections)
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
      end
      puts paged[:next]
      puts paged[:next] == true
      break unless paged[:next] == true
      page = page + 1
    end
  end

  def do_query(page, course)
    ::API[:learnanalytics].rel(:query).get(
        metric: 'CourseEvents',
        course_id: course.id,
        start_time: course.start_date.iso8601,
        end_time: course.end_date.iso8601,
        page: page).value!
  end
end
