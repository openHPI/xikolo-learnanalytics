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

end
