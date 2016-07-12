class LowCourseCommunicationWorker < QcRuleWorker

  def perform(course, rule_id)
    severity = 'low'
    annnotation = "No announcement"
    start_date = course.start_date
    enrollments_threshold = 0

    if course_is_active(course)
      enrollments = Xikolo::Course::Enrollment.where(course_id: course.id, per_page: 1)
      Acfs.run
      total_enrollments = enrollments.total_pages
      if start_date < 10.days.ago and total_enrollments.to_i > enrollments_threshold
        # since its ordered desc
        current_announcements = API[:news].rel(:news_index).get(course_id: course.id, published: "true", page: 1, per_page:1).value!

        if not current_announcements.first or current_announcements.first['publish_at'].to_datetime <= 10.days.ago
          if current_announcements.first
            annnotation = 'Last announcement ' + current_announcements.first['publish_at'].to_datetime.to_formatted_s(:short)
          end
          update_or_create_qc_alert(rule_id, course.id, severity, annnotation)
        else
          find_and_close_qc_alert(rule_id, course.id)
        end
      end
    end
  end
end