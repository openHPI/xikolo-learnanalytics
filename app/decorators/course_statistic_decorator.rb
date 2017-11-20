class CourseStatisticDecorator < ApplicationDecorator
  delegate_all

  def as_json (**opts)
    with_combined_keys(
      id: model.id,
      course_code: model.course_code,
      course_name: model.course_name,
      course_id: model.course_id,
      course_status: model.course_status,
      total_enrollments: model.total_enrollments,
      no_shows: model.no_shows,
      current_enrollments: model.current_enrollments,
      enrollments_last_day: model.enrollments_last_day,
      enrollments_at_course_start: model.enrollments_at_course_start,
      enrollments_at_course_middle_netto: model.enrollments_at_course_middle_netto,
      enrollments_at_course_middle: model.enrollments_at_course_middle,
      enrollments_at_course_end: model.enrollments_at_course_end,
      questions: model.questions, # @deprecated
      questions_last_day: model.questions_last_day, # @deprecated
      answers: model.answers, # @deprecated
      answers_last_day: model.answers_last_day, # @deprecated
      comments_on_answers: model.comments_on_answers, # @deprecated
      comments_on_answers_last_day: model.comments_on_answers_last_day, # @deprecated
      comments_on_questions: model.comments_on_questions, # @deprecated
      comments_on_questions_last_day: model.comments_on_questions_last_day, # @deprecated
      certificates: model.certificates,
      helpdesk_tickets: model.helpdesk_tickets,
      helpdesk_tickets_last_day: helpdesk_tickets_last_day,
      start_date: model.start_date,
      end_date: model.end_date,
      new_users: model.new_users,
      created_at: model.created_at,
      updated_at: model.updated_at,
      completion_rate: model.completion_rate,
      consumption_rate: model.consumption_rate,
      enrollments_per_day: model.enrollments_per_day,
      hidden: model.hidden,
      days_since_coursestart: model.days_since_coursestart,
      questions_in_learning_rooms: model.questions_in_learning_rooms, # @deprecated
      questions_last_day_in_learning_rooms: model.questions_last_day_in_learning_rooms, # @deprecated
      answers_in_learning_rooms: model.answers_in_learning_rooms, # @deprecated
      answers_last_day_in_learning_rooms: model.answers_last_day_in_learning_rooms, # @deprecated
      comments_on_answers_in_learning_rooms: model.comments_on_answers_in_learning_rooms, # @deprecated
      comments_on_answers_last_day_in_learning_rooms: model.comments_on_answers_last_day_in_learning_rooms, # @deprecated
      comments_on_questions_in_learning_rooms: model.comments_on_questions_in_learning_rooms, # @deprecated
      comments_on_questions_last_day_in_learning_rooms: model.comments_on_questions_last_day_in_learning_rooms # @deprecated
    ).as_json(**opts)
  end

  private

  # Add new pinboard fields to the response, that (for now) are calculated from
  # the existing data.
  #
  # The new fields have two changes in comparison to the old, deprecated ones:
  # - instead of questions, answers and comments we now only collect data about
  #   "threads" and "posts"
  # - rename "_in_learning_rooms" to "in_collab_spaces" as the service (and all
  #   corresponding resources) are in the process of being renamed
  def with_combined_keys(hash)
    hash.merge(
      threads: hash[:questions].to_i,
      threads_last_day: hash[:questions_last_day].to_i,
      posts: hash[:questions].to_i +
             hash[:answers].to_i +
             hash[:comments_on_questions].to_i +
             hash[:comments_on_answers].to_i,
      posts_last_day: hash[:questions_last_day].to_i +
                      hash[:answers_last_day].to_i +
                      hash[:comments_on_questions_last_day].to_i +
                      hash[:comments_on_answers_last_day].to_i,
      threads_in_collab_spaces: hash[:questions_in_learning_rooms].to_i,
      threads_last_day_in_collab_spaces: hash[:questions_last_day_in_learning_rooms].to_i,
      posts_in_collab_spaces: hash[:questions_in_learning_rooms].to_i +
                              hash[:answers_in_learning_rooms].to_i +
                              hash[:comments_on_questions_in_learning_rooms].to_i +
                              hash[:comments_on_answers_in_learning_rooms].to_i,
      posts_last_day_in_collab_spaces: hash[:questions_last_day_in_learning_rooms].to_i +
                                       hash[:answers_last_day_in_learning_rooms].to_i +
                                       hash[:comments_on_questions_last_day_in_learning_rooms].to_i +
                                       hash[:comments_on_answers_last_day_in_learning_rooms].to_i
    )
  end
end
