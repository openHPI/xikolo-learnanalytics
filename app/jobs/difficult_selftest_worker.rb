class DifficultSelftestWorker < QcRuleWorker
  def perform(course, rule_id)
    severity = 'medium'
    quiz_items = []
    annotation = ''
    if course_is_active(course)
      Xikolo::Course::Item.each_item(:content_type => 'quiz', exercise_type: %w(main bonus selftest), :course_id => course.id, :published => 'true') do |quiz_item|
        quiz_items << quiz_item
      end
      Acfs.run
      puts quiz_items
      # content_id => quiz_id
      quiz_items.each do |quiz_item|
        puts quiz_item.exercise_type
        #max_points = quiz_item.max_points
        quiz_submission_statistic = Xikolo::Submission::QuizSubmissionStatistic.find(quiz_item.content_id)
        Acfs.run
        #total_submissions = quiz_submission_statistic.total_submissions
        quiz_submission_statistic.questions.each do |question|
          question.each do |question_id, question_info|
            check_under_average_question(course, question_id, question_info, rule_id, severity)
            # is any wrong answer checked by more of 50% of all users
            check_wrong_answers(course, question_info, rule_id, severity)
          end
        end
      end
    end
    # for all self tests, graded homeworks, bonus homworks (not for surveys) for all published courses
  end

  def check_wrong_answers(course, question_info, rule_id, severity)
    threshold_answers = 0.5
    answers = question_info["answers"]
    answers.each do |answer_id, answer|
      submission_count_answer = answer["count"]
      submission_count_question = question_info["count"]
      if submission_count_answer/submission_count_question.to_f >= threshold_answers
        puts "answer over threshold"
        answer_data = Xikolo::Quiz::Answer.find(answer_id)
        Acfs.run
        unless answer_data.correct
          puts "answer is not correct"
          annotation = "Many users selected wrong answer"
          qc_alert_data = create_json(answer_data.id)
          update_or_create_qc_alert_with_data(rule_id, course.id, severity, annotation, answer_data.id, qc_alert_data)
        else
          find_and_close_qc_alert_with_data(rule_id, course.id, answer_data.id)
        end
      else
        find_and_close_qc_alert_with_data(rule_id, course.id, answer_data.id)
      end
    end
  end

  def check_under_average_question(course, question_id, question_info, rule_id, severity)
    # has any question average points less than 50%  (put value to config)
    average_points = question_info["avg_points"]
    quiz_question = Xikolo::Quiz::Question.find(question_id)
    Acfs.run
    points = quiz_question.points
    # has any question average points less than 50%  (put value to config)
    threshold = 0.5
    if average_points/points.to_f <= threshold
      puts ' question average is below 50%'
      qc_alert_data = create_json(quiz_question.id)
      annotation = 'Question average is below 50'
      update_or_create_qc_alert_with_data(rule_id, course.id, severity, annotation, quiz_question.id, qc_alert_data)
    else
      find_and_close_qc_alert_with_data(rule_id, course_id, quiz_question.id)
    end
  end
end