require 'forgery'


FactoryGirl.define do

  factory :video_play_event, class: Hash do
    user(type: :USER, uuid: "00000001-3100-4444-9999-000000000002")
    verb(type: :VIDEO_PLAY)
    resource(type: :ITEM, uuid: "00000003-3100-4444-9999-000000000002")
    # timestamp "2014-10-27T14:59:08+01:00"
    timestamp { Time.now }
    with_result({})
    in_context("currentTime" => "67.698807", "currentSpeed" => "1")
    creation_timestamp { Time.now.to_f }
  end


  factory :viewed_page_event, class: Hash do
    user(type: :USER, uuid: "00000001-3100-4444-9999-000000000002")
    verb("type" => "VIEWED_PAGE")
    resource(type: :PAGE, uuid:"/courses/cloud2013/items/000005iQbuX5nEn1JvgXv4")
    timestamp { Time.now }
    with_result({})
    in_context("user_ip" => "2001:638:807:208:148b:8e62:85ee:547b", "user_os" => "MacIntel", "user_agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.91 Safari/537.36", "user_app_version" => "5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.91 Safari/537.36", "user_location_city" => "Potsdam", "user_location_country_code" => "DE", "user_location_country_name" => "Germany", "user_location_latitude" => "52.4", "user_location_longitude" => "13.067", "user_location_time_zone" => "Europe/Berlin")
    creation_timestamp { Time.now.to_f }
  end

  factory :new_user, class: Hash do
    id                  { '00000001-3100-4444-9999-%012d' % rand(1000000000000) }
    email               "kevin.cool@example.com"
    display_name        "Kevin Cool"
    first_name          "Kevin"
    last_name           "Cool Jr."
    name                "Kevin Cool"
    full_name           "Kevin Cool Jr."
    admin               false
    timezone            nil
    image_id            nil
    legacy_id           nil
    born_at             "Wed, 24 Apr 1985 00:00:00 UTC +00:00"
    archived            false
    password_digest     "$2a$10$yksLzWdw/OJxO/0LFs9pOewXvbVzBnl32WtnQRKOrhP5TExKgs0.O"
    preferred_language  nil
    language            :en
    confirmed           true
    affiliated          false
    created_at          { Time.now }
    updated_at          { Time.now }
  end

  
  factory :new_comment, class: Hash do
    id                { '2f19ab69-4cae-40d6-bb2d-%012d' % rand(1000000000000) }
    text              { Forgery(:lorem_ipsum).words(100) }
    commentable_id    "00000002-3500-4444-9999-000000000001"
    commentable_type  "Question"
    user_id           "00000001-3100-4444-9999-000000000003"
    created_at        { Time.now }
    updated_at        { Time.now }
  end

  factory :new_question, class: Hash do

    id                  { '00000002-3500-4444-9999-%012d' % rand(1000000000000) }
    title               { Forgery(:lorem_ipsum).words(5) }
    text                { Forgery(:lorem_ipsum).words(50) }
    user_id             "00000001-3100-4444-9999-000000000001"
    accepted_answer_id  nil
    course_id           "00000001-3300-4444-9999-000000000001"
    discussion_flag     false
    created_at          { Time.now }
    updated_at          { Time.now }
    votes               1
    views               0
    file_id             nil
    sticky              false
    deleted             false
    closed              false
    implicit_tags       []
    user_tags           ["SQL"]
    creation_timestamp { Time.now.to_f }
  end

end
