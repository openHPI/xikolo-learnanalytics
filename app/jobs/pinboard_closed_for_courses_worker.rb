class PinboardClosedForCoursesWorker < QcRuleWorker
  def perform(course, rule_id)
    severity = 'low'
    annotation = 'Pinboard still open in an archived course'
    if not course_is_active(course)
      if course.status == 'archive' and course.start_date <= DateTime.now
        if course.forum_is_locked.nil? or course.forum_is_locked == false
          update_or_create_qc_alert(rule_id, course.id, severity, annotation)
        else
          find_and_close_qc_alert(rule_id, course.id)
        end
      end
    else
      find_and_close_qc_alert(rule_id, course.id)
    end
  end
end