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

  factory :amqp_user, class: Hash do
    id "00000001-3100-4444-9999-000000000001"
    email "kevin.cool@example.com"
    display_name "Kevin Cool"
    first_name "Kevin"
    last_name "Cool Jr."
    name "Kevin Cool"
    full_name "Kevin Cool Jr."
    admin false
    language "en"
    timezone nil
    image_id nil
    legacy_id nil
    born_at "1985-04-24T00:00:00.000Z"
    archived false
    password_digest "$2a$10$v93d1K4Jw8ur/Ki0Yz69ouSnjTielvB3eb4WZJ95V6yxPZSi/rcYy"
    created_at "2014-10-20T19:56:31.268Z"
    confirmed true
    emails_url "http://localhost:3100/users/00000001-3100-4444-9999-000000000001/emails"
    email_url "http://localhost:3100/users/00000001-3100-4444-9999-000000000001/emails/{id}"
    self_url "http://localhost:3100/users/00000001-3100-4444-9999-000000000001"
    blurb_url "http://localhost:3100/users/00000001-3100-4444-9999-000000000001/blurb"
    affiliated false
  end

end
