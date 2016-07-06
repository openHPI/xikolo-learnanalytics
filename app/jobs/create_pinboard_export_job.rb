class CreatePinboardExportJob < CreateExportJob
  queue_as :default

  def perform(job_id, password, user_id, course_id, privacy_flag)
    job = find_and_save_job(job_id)
    begin
      course = Xikolo::Course::Course.find(course_id)
      Acfs.run
      job.annotation = course.course_code.to_s
      job.save
      temp_report, temp_excel_report = create_report(job_id, course_id, privacy_flag)
      csv_name = get_tempdir.to_s + '/PinboardExport_' + course.course_code.to_s + "_" + DateTime.now.strftime('%Y-%m-%d-%H-%M-%S') + '.csv'
      excel_name = get_tempdir.to_s + '/PinboardExport_' + course.course_code.to_s + "_" + DateTime.now.strftime('%Y-%m-%d-%H-%M-%S') + '.xlsx'
      additional_files = []
      create_file(job_id, csv_name, temp_report.path, excel_name, temp_excel_report.path, password, user_id, course_id, additional_files)
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
      excel_tmp_file =  Tempfile.new('excel_pinboard_export', get_tempdir)
      headers = []
      pinboard_info = []
      csv = CSV.new(file)
      write_header(csv, headers)
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
          write_question(csv, pinboard_type, question, pinboard_info)
          if question.discussion_flag == false
            get_comments(question, csv, "Question", pinboard_info)
            get_answers(question, csv, pinboard_info)
          else
            get_comments(question, csv, "Question", pinboard_info)
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
    Acfs.run
    excel_file = excel_attachment('PinboardExport', excel_tmp_file, headers, pinboard_info)
    excel_file.close
    file.close

    return file, excel_file
  end

  def write_header(csv, headers)
    headers += ['id',
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
    csv << headers
  end

  def write_question(csv, pinboard_type, question, pinboard_info)
    current_question = [question.id,
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
    pinboard_info += current_question
    csv << current_question
  end

  def get_answers(question, csv, pinboard_info)
    answer_pager = 1
    answer_page_size = 50
    answers = Xikolo::Pinboard::Answer.where(question_id: question.id, per_page: answer_page_size, page: answer_pager)
    Acfs.run
    loop do
      answers.each do |answer|
        current_answer = [answer.id,
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
        csv << current_answer
        pinboard_info += current_answer
        # get comments for each answer
        get_comments(answer, csv, "Answer", pinboard_info)
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

  def get_comments(object, csv, type, pinboard_info)
    comments_size = 0
    Xikolo::Pinboard::Comment.each_item(commentable_id: object.id, commentable_type: type) do |comment|

      question_id = ''
      if comment.commentable_type == 'Question'
        question_id = comment.commentable_id
      elsif comment.commentable_type == 'Answer'
        question_id = object.question_id
      end


      current_comment = [comment.id,
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
      csv << current_comment
      pinboard_info += current_comment
      comments_size += 1
    end
    Acfs.run
  end
end

