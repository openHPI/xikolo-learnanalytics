FactoryGirl.define do
  
  factory :amqp_enrollment, class: Hash do
    id         "7d7a317c-825d-4134-b1c1-db2b9f236667"
    user_id    "00000001-3100-4444-9999-000000000001"
    course_id  "00000001-3300-4444-9999-000000000006"
    role       "student"
    url        "/enrollments/7d7a317c-825d-4134-b1c1-db2b9f236667"
    created_at "2014-10-20T13:13:21.621Z"
  end

  factory :amqp_course, class: Hash do
    id "596420be-95ec-4586-9c4c-b76b31593217"
    title "testkurs"
    start_date "2014-08-21T00:00:00Z"
    display_start_date nil
    end_date "2014-11-21T00:00:00Z"
    abstract ""
    description_rtid "22d7355a-b72b-4542-b5fa-cd95913c88e1"
    visual_id nil
    lang "de"
    categories []
    teacher_ids []
    teaching_team_ids []
    course_code "test-kurs"
    status "preparation"
    vimeo_id nil
    has_teleboard false
    records_released false
    url "/courses/596420be-95ec-4586-9c4c-b76b31593217"
    enrollment_delta 0
    alternative_teacher_text ""
    external_course_url ""
    external_course_delay 0
    forum_is_locked false
    affiliated false
    hidden false
    welcome_mail ""
  end

end
