class NoShowWorker < QcRuleWorker

  def perform(course, rule_id)
    severity = 'medium'
    annotation = 'High no-show rate: '
    threshold = 0

    if course_is_active(course) && course.start_date.present?
      no_show_rate = calculate_no_shows(course)
      if DateTime.now.between?(course.start_date + 24.hours, course.start_date + 48.hours)
        threshold = Xikolo.config.qc_alert['no_show_rate']['24_hours']
      elsif DateTime.now.between?(course.start_date + 48.hours, course.start_date + 7.days)
        threshold = Xikolo.config.qc_alert['no_show_rate']['48_hours']
      elsif DateTime.now >= course.start_date + 7.days
        threshold = Xikolo.config.qc_alert['no_show_rate']['7_days']
      end

      if no_show_rate >= threshold
        update_or_create_qc_alert(rule_id, course.id, severity, annotation + no_show_rate.to_s)
      else
        find_and_close_qc_alert(rule_id, course.id)
      end
    end
  end

  def calculate_no_shows(course)
   course_stats = ::API[:course].rel(:stats).get(course_id: course.id, key: 'extended').value!
   enrollments = course_stats['student_enrollments']
   no_shows = course_stats['no_shows']
   percentage_noshows = 0
   percentage_noshows = (no_shows * 100/enrollments.to_f).round(2) unless enrollments.to_f == 0
   return percentage_noshows
  end
end
