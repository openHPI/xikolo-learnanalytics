FactoryGirl.define do

  factory :amqp_pinboard_question, class: Hash do
    id "9dcedafc-e6d1-4dd3-adc2-436fecf2baf0"
    title "Test Question 0"
    text "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"
    video_timestamp nil
    video_id nil
    user_id "00000001-3100-4444-9999-000000000002"
    accepted_answer_id nil
    course_id "00000001-3300-4444-9999-000000000001"
    learning_room_id nil
    discussion_flag false
    created_at "2014-10-17T20:00:24Z"
    updated_at "2014-10-20T20:00:24Z"
    votes 0
    views 0
    file_id nil
    sticky false
    deleted false
    closed false
    implicit_tags []
    user_tags ["HTTP", "Rendering", "HTML"]
    answer_count 0
    comment_count 0
    answer_comment_count 0
  end

  factory :amqp_pinboard_learning_room_question, parent: :amqp_pinboard_question do
    course_id nil
    learning_room_id "00000001-3300-4444-9999-000000000001"
  end

  factory :amqp_pinboard_question_subscription, class: Hash do
    id "803b458b-1ee1-45d4-bed1-c52f43c6502c"
    user_id "00000001-3100-4444-9999-000000000001"
    question_id "00000002-3500-4444-9999-000000000001"
    created_at "2014-10-20T20:00:26.550Z"
  end

  factory :amqp_pinboard_question_comment, class: Hash do
    id "4fb3c476-9c33-407c-8d58-7c8bddcc3a3d"
    text "Test Ccmment 0"
    user_id "00000001-3100-4444-9999-000000000003"
    commentable_id "00000002-3500-4444-9999-000000000001"
    commentable_type "Question"
    created_at "2014-10-20T20:00:25Z"
    updated_at "2014-10-20T20:00:25Z"
  end

  factory :amqp_pinboard_answer_comment, parent: :amqp_pinboard_question_comment do
    commentable_id "00000003-3500-4444-9999-000000000001"
    commentable_type "Answer"
  end

end
