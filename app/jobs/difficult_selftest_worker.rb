class DifficultSelftestWorker < QcRuleWorker
  def perform(course, rule_id)
    severity = 'high'
    if course_is_active(course)
      Xikolo::Course::Item.each_item(:content_type => 'quiz', exercise_type: 'selftest' :course_id => course.id, :published => 'true') do |item|
        items << item
      end
      Acfs.run
      # content_id => quiz_id

    items.each do |item |
      Xikolo::Submission::QuizSubmissionStatistics.each_item(:id => item.content_id)

    end
    end
    # submission_statistic
    # for all self tests, graded homeworks, bonus homworks (not for surveys) for all published courses
    # has any question avergae points less than 50%  (put value to config)
    # is any wrong answer checked by more of 50% of all users
  end
end