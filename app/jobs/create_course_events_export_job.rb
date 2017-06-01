class CreateCourseEventsExportJob < CreateExportJob
  queue_as :default

  def perform(job_id, password, user_id, course_id, privacy_flag)
    job = find_and_save_job (job_id)

    begin
      course = Xikolo::Course::Course.find(course_id)
      Acfs.run
      job.annotation = course.course_code.to_s
      job.save
      temp_report = create_report(job_id, course_id, privacy_flag)
      csv_name = "#{get_tempdir}/CourseEventsExport_#{course_id}_#{DateTime.now.strftime('%Y-%m-%d')}.csv"
      create_file(job_id, csv_name, temp_report.path, password, user_id, course_id)
    rescue => error
      Sidekiq.logger.error error.inspect
      job.status = 'failing'
      job.save
      File.delete(temp_report) if File.exist?(temp_report)
    end
  end

  private

  def create_report(job_id, course_id, privacy_flag)
    file = Tempfile.open(job_id.to_s, get_tempdir)
    headers = []
    @filepath = File.absolute_path(file)

    course = Xikolo::Course::Course.find(course_id)
    items = ActiveSupport::HashWithIndifferentAccess.new
    sections = ActiveSupport::HashWithIndifferentAccess.new

    # we may need to include deleted if there is usage data for those
    Xikolo::Course::Section.each_item(course_id: course_id) do |section|
      sections[section.id] = section
    end
    Xikolo::Course::Item.each_item(course_id: course_id) do |item|
     items[item.id] = item
    end
    Acfs.run

    CSV.open(@filepath, 'wb') do |csv|
      headers += ['Course ID', 'User', 'Verb', 'Resource', 'Timestamp', 'Context', 'Type', 'Title', 'Section' ]
      csv << headers
      Sidekiq.logger.debug 'Writing export to '+ @filepath + " \n" + 'with headers ' + headers.to_s
      if course.start_date.present? and course.end_date.present?
        get_all(course, csv, items, sections)
      end
    end
    Acfs.run
    return file
  ensure
    file.close
  end

  def update_job_progress(job_id, percent)
    job = Job.find(job_id)
    job.progress = percent
    job.save!
  end

  def get_all(course, csv, items, sections)
    page = 1
    scroll_id = nil

    loop do
      paged = do_query(page, course, scroll_id)

      Sidekiq.logger.debug "Processing data: #{paged[:data].size} items of page #{page}"

      paged[:data].each do |item|
        # deprecated event
        next if item[:verb] == 'VISITED'

        if item[:verb] == 'VISITED_ITEM'
          begin
            id = item[:resource]
            item[:type] = items[id].content_type
            item[:title] = items[id].title
            item[:section] = sections[items[id].section_id].title
          rescue
            item[:type] = ''
            item[:title] = ''
            item[:section] = ''
          end
        else
          item[:type] = ''
          item[:title] = ''
          item[:section] = ''
        end

        csv << item.values
        csv.flush
      end

      scroll_id = paged[:scroll_id]
      break unless paged[:next]
      page += 1
    end
  end

  def do_query(page, course, scroll_id)
    Lanalytics::Metric::CourseEvents.query(
      nil,
      course.id,
      course.start_date.iso8601,
      course.end_date.iso8601,
      nil,
      page,
      nil,
      scroll_id)
  end

end
