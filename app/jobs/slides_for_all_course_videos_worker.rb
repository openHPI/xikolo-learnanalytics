class SlidesForAllCourseVideosWorker < QcRuleWorker

  def perform(course, rule_id)
    severity = 'high'
    annotation = 'Slide based Navigation '
    result = []
    start_date = course.start_date
    if start_date and start_date <= DateTime.now + 2.days
      return if course.status != 'preparation'
      items = Xikolo::Course::Item.all(:content_type => 'video', :course_id => course.id )
      Acfs.run

      items.each do |item|
        unless  item.content_id.nil? or item.content_id.empty?
          video = Xikolo::Video::Video.find(item.content_id)
          Acfs.run
          if video.thumbnail_archive_id.nil? or video.thumbnail_archive_id.empty?
            result.push(video.title)
          end
        end
      end
      if result.nil? or result.empty?
        find_and_close_qc_alert(rule_id, course.id)
      else
        video_titles = result.join(", ")
        annotation<<video_titles
        update_or_create_qc_alert(rule_id, course.id, severity, annotation)
      end
    end
  end
end