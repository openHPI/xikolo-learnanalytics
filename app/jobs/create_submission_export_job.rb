class CreateSubmissionExportJob < CreateExportJob
  queue_as :default

  def perform(job_id, password, user_id, quiz_id, privacy_flag)
    job = find_and_save_job (job_id)

    begin
      item = Xikolo.api(:course).value!.rel(:items).get(content_id: quiz_id).value!.first
      job.annotation = item['title'].parameterize.underscore
      job.save
      temp_report = create_report(job_id, quiz_id, privacy_flag)
      csv_name = get_tempdir.to_s + '/SubmissionExport_' + quiz_id.to_s + '_' + DateTime.now.strftime('%Y-%m-%d') + '.csv'
      create_file(job_id, csv_name, temp_report.path, false, false, password, user_id, quiz_id, nil)
    rescue => error
      Sidekiq.logger.error error.inspect
      job.status = 'failing'
      job.save
      File.delete(temp_report) if File.exist?(temp_report)
    end
  end

  private

  def create_report(job_id, quiz_id, privacy_flag)
    file = Tempfile.open(job_id.to_s, get_tempdir)
    headers = []
    @filepath = File.absolute_path(file)
    p = 1

    Sidekiq.logger.info "Writing export to #{@filepath}"
    @submissions = {}
    Xikolo::Quiz::Quiz.find(quiz_id) do |quiz|

      @quiz_questions = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

      quiz.enqueue_acfs_request_for_questions do |quiz_questions|

        quiz_questions.each do |quiz_question|

          Xikolo::RichText::RichText.find(quiz_question.question_rtid) do |q_richtext|
            @quiz_questions[quiz_question.id][:question_text] = q_richtext.markup
          end

          @quiz_questions[quiz_question.id][:answers] = []

          quiz_question.enqueue_acfs_request_for_answers do |quiz_answers|
            quiz_answers.each do |quiz_answer|

              Xikolo::RichText::RichText.find(quiz_answer.answer_rtid) do |a_richtext|
                @quiz_questions[quiz_question.id][:answers] << {:id => quiz_answer.id, :answer_text => a_richtext.markup}
              end
            end
          end
        end
      end
    end

    Acfs.run

    total_quizzes = @quiz_questions.size
    Xikolo::Submission::QuizSubmission.each_item(quiz_id: quiz_id, only_submitted: 'true')  do |submission|
      p += 1
      update_job_progress(job_id, p, total_quizzes)

      @submissions[submission.id] = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
      @submissions[submission.id][:created_at] = submission.quiz_submission_time
      @submissions[submission.id][:user_id] = submission.user_id

      Xikolo::Account::User.find(submission.user_id) do |user|
        @submissions[submission.id][:user_name] = user.first_name + ' ' + user.last_name
        @submissions[submission.id][:user_email] = user.email
      end

      submission.enqueue_acfs_request_for_quiz_submissions_questions do |submission_questions|

        submission_questions.each do |submission_question|
          @submissions[submission.id][:questions][submission_question.quiz_question_id][:selected_answers] = []

          submission_question.enqueue_acfs_request_for_quiz_submissions_answers do |submission_answers|
            submission_answers.each do |submission_answer|

              if 'Xikolo::Submission::QuizSubmissionFreeTextAnswer' == submission_answer.class.name
                @submissions[submission.id][:questions][submission_question.quiz_question_id][:freetext_answer] = submission_answer.user_answer_text
              else
                @submissions[submission.id][:questions][submission_question.quiz_question_id][:selected_answers] << submission_answer.quiz_answer_id
                @submissions[submission.id][:questions][submission_question.quiz_question_id][:freetext_answer] = ''
              end
            end
          end


        end
      end

    end
    Acfs.run

    CSV.open(@filepath, 'wb') do |csv|
      headers += ['User ID',
                  'User Name',
                  'Email',
                  'Submitted On',
                  'Points',
      ]

      current_question = []
      @quiz_questions.each do |_, question|
        current_question << [question[:question_text]]
        question[:answers].each do |answer|
          current_question += [answer[:answer_text]]
        end
      end
      headers += current_question
      csv << headers
      @submissions.each do |_, submission|
        current_submission = []
        current_submission += [submission[:user_id],
                               submission[:user_name],
                               submission[:user_email],
                               submission[:created_at],
                               submission[:points]
        ]

        @quiz_questions.each do |key, question|
          current_submission += ['']
          sub_q = submission[:questions][key]
          question[:answers].each do |quiz_a|

            if sub_q[:selected_answers].include? quiz_a[:id]
              current_submission += ['x']
            else
              current_submission += [sub_q[:freetext_answer]]
            end
          end
        end
        csv << current_submission
        csv.flush
      end
    end
    Acfs.run

    return file
  ensure
    file.close
  end

  def update_job_progress(job_id, p, total_questions)
    job = Job.find(job_id)
    current = p/total_questions.to_f
    total = (current * 100).to_i
    job.progress = total
    job.save!
  end

end
