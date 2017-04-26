class QuizPerformanceWorker < QcRuleWorker
  def perform(course, rule_id)
    avg_percentage_threshold = Xikolo.config.qc_alert["quiz_performance"]["avg_percentage_threshold"]
    avg_first_attempt_percentage_threshold = Xikolo.config.qc_alert["quiz_performance"]["avg_first_attempt_percentage_threshold"]
    avg_attempts_threshold = Xikolo.config.qc_alert["quiz_performance"]["avg_attempts_threshold"]
    severity = 'medium'
    items = Xikolo::Course::Item.all(:content_type => 'quiz', :course_id => course.id, :published => 'true', :exercise_type => ['main', 'selftest'])
    Acfs.run
    items.each do |item|
      quiz_performance = calculate_metrics(item, course)
      if quiz_performance
        avg_points = quiz_performance["average_points_percentage"].round(2)
        avg_attempts = quiz_performance["avg_attempts"].round(2)
        first_attempt_avg_points = quiz_performance["average_points_percentage_first_attempt"].round(2)
        total = quiz_performance["total"]
        if total >= 10
          if avg_attempts >=  avg_attempts_threshold or avg_points <= avg_percentage_threshold or first_attempt_avg_points <= avg_first_attempt_percentage_threshold
            annotation = "Quiz performance low: avg attempts #{avg_attempts}, avg_performance: #{avg_points}, first_attempt_avg: #{first_attempt_avg_points}"
            update_or_create_qc_alert_with_data(rule_id, course.id, severity, annotation + avg_points.to_s, item.id, create_json(item.id))
          else
            find_and_close_qc_alert_with_data(rule_id, course.id, item.id)
          end
        end
      end
    end
  end

  def calculate_metrics(item, course)
    quiz_performance = Lanalytics::Metric::QuizPerformance.query(
        nil,
        course.id,
        nil,
        nil,
        item.id,
        nil,
        nil)
    return quiz_performance
  end
end