class DifficultSelftestWorker < QcRuleWorker
  def perform(course, rule_id)
    severity = 'high'
    quiz_items = []
    annotation = 'Question average is below 50'
    if course_is_active(course)
      Xikolo::Course::Item.each_item(:content_type => 'quiz', exercise_type: 'selftest', :course_id => course.id, :published => 'true') do |quiz_item|
        quiz_items << quiz_item
      end
      Acfs.run
      # content_id => quiz_id

      quiz_items.each do |quiz_item|
        qc_alert_data = create_json(quiz_item.content_id)
        max_points = quiz_item.max_points
        puts "Max points for quiz #{max_points}"
        quiz_submission_statistic = Xikolo::Submission::QuizSubmissionStatistic.find(quiz_item.content_id)
        Acfs.run
        total_submissions = quiz_submission_statistic.total_submissions
        puts "Total Submissions: #{total_submissions}"
        quiz_submission_statistic.questions.each do |question|
          question.each do |question_id, question_info|
            puts '#Question'
            average_points = question_info["avg_points"]
            quiz_question = Xikolo::Quiz::Question.find(question_id)
            Acfs.run
            puts "Possible points per question: #{quiz_question.points}"
            puts "Average points per question #{average_points}"
            # has any question average points less than 50%  (put value to config)
            threshold = 0.5
            if average_points/quiz_question.points > threshold
              update_or_create_qc_alert_with_data(rule_id, course.id, severity, annotation, qc_alert_data)
            end
            # is any wrong answer checked by more of 50% of all users
            puts "Total Submission count per question: #{question_info["count"]}"
            puts "    #Answers"

            answers = question_info["answers"]
            answers.each do |answer_id, answer|
              if answer["count"]/question_info["count"].to_f >= threshold
                puts "answer over threshold"
                answer_data = Xikolo::Quiz::Answer.find(answer_id)
                unless answer_data.correct
                  puts "answer is not correct"
                  annotation = "answer has many wrongs"
                  update_or_create_qc_alert_with_data(rule_id, course.id, severity, annotation, qc_alert_data)
                end
              end
            end



          end
        end

      end
    end
    # for all self tests, graded homeworks, bonus homworks (not for surveys) for all published courses


  end

  def create_json(resource_id)
    {"resource_id" => resource_id}
  end
end