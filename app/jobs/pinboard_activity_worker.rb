class PinboardActivityWorker < QcRuleWorker

  def perform(course, rule_id)
    ##
    # Every Rule is handled by a worker.
    # A worker have
    # - preconditions
    # - checks and thresholds
    # - severity level
    # - linked recommendations
    severity = 'low'
    start_date = course.start_date
    threshold = 0.025
    enrollments_threshold = 100

    if course_is_active(course)
      enrollments = Xikolo::Course::Enrollment.where(course_id: course.id, per_page: 1)
      Acfs.run
      total_enrollments = enrollments.total_pages

      # Check preconditions
      # - enrollments > 100
      # - start_date is older than 24 h

      if total_enrollments.to_i >= enrollments_threshold and start_date < 2.day.ago
        start_time_for_activity = [start_date, (Date.today - 7.days)].max
        # Check
        activity =  Lanalytics::Metric::PinboardActivity.query(
                      nil,
                      course.id,
                      start_time_for_activity.iso8601,
                      Time.now.iso8601,
                      nil,
                      nil,
                      nil)[:count]
        course_runtime_in_days = (Date.today - start_date).to_i
        course_analysis_time = Date.today - start_time_for_activity
        if (total_enrollments.to_f * course_analysis_time.to_f) != 0
          normalized_activity = activity / (total_enrollments.to_f * course_analysis_time.to_f)
        else
          normalized_activity = activity
        end
        if normalized_activity < threshold
          severity = 'medium' if normalized_activity < threshold/2
          severity = 'high'   if normalized_activity < threshold/4
          update_or_create_qc_alert(rule_id, course.id, severity, 'Norm. activity ' + normalized_activity.to_s)
        else
          find_and_close_qc_alert(rule_id, course.id)
        end
      end
    else
      #alert can be closed if course is closed
      find_and_close_qc_alert(rule_id, course.id)
    end
  end
end
