class CreatePinboardExportJob < CreateExportJob
  queue_as :default

  def perform(job_id, password, user_id, course_id, privacy_flag)
    job = find_and_save_job(job_id)
    begin
      course = Xikolo::Course::Course.find(course_id)
      Acfs.run
      job.annotation = course.course_code.to_s
      job.save
      temp_report = create_report(job_id, course_id, privacy_flag)
      csv_name = get_tempdir.to_s + '/PinboardExport_' + course.course_code.to_s + "_" + DateTime.now.strftime('%Y-%m-%d-%H-%M-%S') + '.csv'
      additional_files = []
      create_file(job_id, csv_name, temp_report, password, user_id, course_id, additional_files)
    rescue => error
      puts error.inspect
      job.status = 'failing'
      job.save
    end
  end

  private
  def create_report(job_id, course_id, privacy_flag)
    begin
      question_page_size = 50
      question_pager = 1
      #pinboardexport
      file = Tempfile.open(job_id.to_s, get_tempdir)
      csv = CSV.new(file)
      write_header(csv)
      question_count = 0
      loop do
        questions = Xikolo::Pinboard::Question.where(course_id: course_id, per_page: question_page_size, page: question_pager)
        Acfs.run
        total_questions = questions.total_pages
        questions.each do|question|
          question_count += 1
          update_job_progress(job_id, question_count, total_questions)
          if question.discussion_flag == true
            pinboard_type = 'discussion'
          else
            pinboard_type = 'question'
          end
          write_question(csv, pinboard_type, question)
          if question.discussion_flag == false
            get_comments(question, csv, "Question")
            get_answers(question, csv)
          else
            get_comments(question, csv, "Question")
          end
        end
        $stdout.print 'Fetching page ' + question_pager.to_s + ' from ' + questions.total_pages.to_s + ' \n'
        question_pager +=1
        break if questions.total_pages == 0
        break if (questions.current_page >= questions.total_pages)
      end
      $stdout.print 'Writing export to '+ file.path + " \n"

      #rescue Exception => e
      #puts e.message
    end
    file.close
    Acfs.run
    file
  end

  def write_header(csv)
    csv<<['id',
          'type',
          'title',
          'text',
          'video_timestamp',
          'video_id',
          'user_id',
          'created_at',
          'updated_at',
          'accepted_answer_id',
          'course_id',
          'learning_room_id',
          'question_id',
          'file_id',
          'commentable_id',
          'commentable_type',
          'answer_prediction',
          'sentiment',
          'sticky',
          'deleted',
          'closed',

    ]
  end

  def write_question(csv, pinboard_type, question)
    csv<< [question.id,
           pinboard_type,
           question.title,
           question.text.squish ,
           question.video_timestamp,
           question.video_id,
           question.user_id,
           question.created_at,
           question.updated_at,
           question.accepted_answer_id,
           question.course_id,
           question.learning_room_id,
           question.id,
           '',
           '',
           '',
           '',
           question.sentimental_value,
           question.sticky,
           question.deleted,
           question.closed
    ]
  end

  def get_answers(question, csv)
    answer_pager = 1
    answer_page_size = 50
    answers = Xikolo::Pinboard::Answer.where(question_id: question.id, per_page: answer_page_size, page: answer_pager)
    Acfs.run
    loop do
      answers.each do |answer|
        csv <<[answer.id,
               "answer",
               '',
               answer.text.squish ,
               '',
               '',
               answer.user_id,
               answer.created_at,
               answer.updated_at,
               '',
               '',
               '',
               answer.question_id,
               answer.file_id,
               '',
               '',
               answer.answer_prediction,
               answer.sentimental_value,
        ]
        # get comments for each answer
        get_comments(answer, csv, "Answer")
      end
      answer_pager += 1
      break if answers.total_pages == 0
      break if (answers.current_page >= answers.total_pages)
    end
  end

  def update_job_progress(job_id, current_question_count, total_questions)
    if total_questions != 0
      job = Job.find(job_id)
      current = current_question_count/total_questions.to_f
      total = (current * 100).to_i
      job.progress = total
      job.save!
    end
  end

  def get_comments(object, csv, type)
    comments_size = 0
    Xikolo::Pinboard::Comment.each_item(commentable_id: object.id, commentable_type: type) do |comment|

      question_id = ''
      if comment.commentable_type == 'Question'
        question_id = comment.commentable_id
      elsif comment.commentable_type == 'Answer'
        question_id = object.question_id
      end


      csv << [comment.id,
              "comment",
              '',
              comment.text.squish ,
              '',
              '',
              comment.user_id,
              comment.created_at,
              comment.updated_at,
              '',
              '',
              '',
              question_id,
              '',
              comment.commentable_id,
              comment.commentable_type,
              '',
              comment.sentimental_value,
      ]
      comments_size += 1
    end
    Acfs.run
  end
end

