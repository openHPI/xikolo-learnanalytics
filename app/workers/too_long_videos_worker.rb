class TooLongVideosWorker < QcRuleWorker

  def perform(course, rule_id)
    severity = 'medium'
    annotation = 'Video is too long'
    items = []
    if course.end_date.present? && course.end_date < DateTime.now
      find_and_close_qc_alert(rule_id, course.id)
    elsif course.status == 'active' or course.status == 'archive'
      Xikolo::Course::Item.each_item(:content_type => 'video', :course_id => course.id, :published => 'true') do |item|
        items << item
      end
      Acfs.run
      items.each do |item|
        video = {}
        if item.content_id.present?
          video = Xikolo.api(:video).value!.rel(:video).get(id: item.content_id).value!
        end
        duration_in_min = 0
        duration_in_min = video['duration'] / 60 if video['duration']
        video_annotation = "#{annotation} (#{duration_in_min} min): #{video['title']}"

        if duration_in_min.between?(Xikolo.config.qc_alert['video_duration']['low'], Xikolo.config.qc_alert['video_duration']['medium'])
          severity = 'low'
          update_or_create_qc_alert_with_data(rule_id, course.id, severity, video_annotation, item.id, create_json(item.id))
        elsif duration_in_min.between?(Xikolo.config.qc_alert['video_duration']['medium'], Xikolo.config.qc_alert['video_duration']['high'])
          severity = 'medium'
          update_or_create_qc_alert_with_data(rule_id, course.id, severity, video_annotation, item.id, create_json(item.id))
        elsif duration_in_min > Xikolo.config.qc_alert['video_duration']['high']
          severity = 'high'
          update_or_create_qc_alert_with_data(rule_id, course.id, severity, video_annotation, item.id, create_json(item.id))
        else
          find_and_close_qc_alert_with_data(rule_id, course.id, item.id)
        end
      end
    end
  end
end