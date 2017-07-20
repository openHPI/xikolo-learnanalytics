module Reports
  class SubmissionReport < Base
    def initialize(job, params = {})
      super

      @anonymize = params[:privacy_flag]
    end

    def generate!
      @job.update(annotation: "#{item['title'].parameterize.underscore} (#{@job.task_scope})")

      csv_file "SubmissionReport_#{@job.task_scope}", headers, &method(:each_submission)
    end

    private

    def headers
      headers = ['User ID']

      unless @anonymize
        headers.concat [
         'User Name',
         'Email',
        ]
      end

      headers.concat [
        'Submitted On',
        'Points',
      ]

      headers.concat all_quiz_questions.flat_map { |_, question|
        [question[:question_text], *question[:answers].map { |answer| answer[:answer_text] }]
      }
    end

    def each_submission
      i = 0
      Xikolo::Submission::QuizSubmission.each_item(
        quiz_id: @job.task_scope, only_submitted: 'true'
      )  do |submission, submissions|
        submission_hash = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
        submission_hash[:created_at] = submission.quiz_submission_time
        submission_hash[:user_id] = submission.user_id

        user = account_service.rel(:user).get(id: submission.user_id).value!
        submission_hash[:user_name] = user['full_name']
        submission_hash[:user_email] = user['email']

        submission_service.rel(:quiz_submission_questions).get(
          quiz_submission_id: submission.id, per_page: 250
        ).value!.each do |submission_question|
          submission_hash[:questions][submission_question['quiz_question_id']][:selected_answers] = []

          submission_service.rel(:quiz_submission_answers).get(
            quiz_submission_question_id: submission_question['id'], per_page: 500
          ).value!.each do |submission_answer|
            if 'Xikolo::Submission::QuizSubmissionFreeTextAnswer' == submission_answer['type']
              submission_hash[:questions][submission_question['quiz_question_id']][:freetext_answer] = submission_answer['user_answer_text']
            else
              submission_hash[:questions][submission_question['quiz_question_id']][:selected_answers] << submission_answer['quiz_answer_id']
              submission_hash[:questions][submission_question['quiz_question_id']][:freetext_answer] = ''
            end
          end
        end

        yield transform_submission(submission_hash)

        i += 1
        @job.progress_to(i, of: submissions.total_count)
      end
      Acfs.run
    end

    def transform_submission(row)
      values = [@anonymize ? Digest::SHA256.hexdigest(row[:user_id]) : row[:user_id]]

      unless @anonymize
        values += [
          row[:user_name],
          row[:user_email],
        ]
      end

      values += [
        row[:created_at],
        row[:points],
      ]

      values + all_quiz_questions.flat_map { |key, question|
        # For each question, we add an empty column (for the quiz question)
        # and one column for each possible answer.
        [''] + question[:answers].map { |answer|
          if row[:questions][key][:selected_answers].include? answer[:id]
            '1'
          else
            row[:questions][key][:freetext_answer]
          end
        }
      }
    end

    def all_quiz_questions
      @all_quiz_questions ||= load_all_quiz_questions
    end

    def load_all_quiz_questions
      hash = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

      Xikolo::Quiz::Quiz.find(@job.task_scope) do |quiz|
        quiz.enqueue_acfs_request_for_questions do |quiz_questions|

          quiz_questions.each do |quiz_question|

            Xikolo::RichText::RichText.find(quiz_question.question_rtid) do |q_richtext|
              hash[quiz_question.id][:question_text] = q_richtext.markup
            end

            hash[quiz_question.id][:answers] = []

            quiz_question.enqueue_acfs_request_for_answers do |quiz_answers|
              quiz_answers.each do |quiz_answer|

                Xikolo::RichText::RichText.find(quiz_answer.answer_rtid) do |a_richtext|
                  hash[quiz_question.id][:answers] << {id: quiz_answer.id, position: quiz_answer.position, answer_text: a_richtext.markup}
                end
              end
            end

            hash[quiz_question.id][:answers].sort_by! { |answer| answer[:position] }
          end
        end
      end

      Acfs.run

      hash
    end

    def item
      @item ||= course_service.rel(:items).get(content_id: @job.task_scope).value!.first
    end

    def account_service
      @account_service ||= Xikolo.api(:account).value!
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end

    def submission_service
      @submission_service ||= Xikolo.api(:submission).value!
    end
  end
end
