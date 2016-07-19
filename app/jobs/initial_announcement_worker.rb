class InitialAnnouncementWorker < QcRuleWorker

  def perform(course, rule_id)
    severity = 'low'
    annnotation = 'No initial mail announcement before course start'
    enrollments_threshold = 1
    start_date = course.start_date
    enrollments = Xikolo::Course::Enrollment.where(course_id: course.id, per_page: 1)
    Acfs.run
    total_enrollments = enrollments.total_pages
    if course.end_date.present? && course.end_date < DateTime.now
      find_and_close_qc_alert(rule_id, course.id)
    elsif start_date.present? && start_date < 7.business_days.from_now  && total_enrollments.to_i > enrollments_threshold
      mail_sent_flag = false
      API[:news].rel(:news_index).get(course_id: course.id, published: "true").value!.each do |announcement|
        if announcement.present?
          if announcement['sending_state'].present?
            sending_state = announcement['sending_state']
          else
            sending_state = 0
          end
          if announcement['publish_at'].present?
            if sending_state > 0 && announcement['publish_at'] <= start_date
              mail_sent_flag = true
            end
          end
        end
      end

      if not mail_sent_flag
        severity = 'high'  if start_date < 4.business_days.from_now
        update_or_create_qc_alert(rule_id, course.id, severity, annnotation)
      else
        find_and_close_qc_alert(rule_id, course.id)
      end
    else
      find_and_close_qc_alert(rule_id, course.id)
    end
  end
end


