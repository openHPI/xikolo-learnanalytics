FactoryBot.define do
  
  factory :amqp_enrollment, class: Hash do
    id         "7d7a317c-825d-4134-b1c1-db2b9f236667"
    user_id    "00000001-3100-4444-9999-000000000001"
    course_id  "00000001-3300-4444-9999-000000000006"
    role       "student"
    url        "/enrollments/7d7a317c-825d-4134-b1c1-db2b9f236667"
    created_at "2014-10-20T13:13:21.621Z"
  end

  factory :amqp_course, class: Hash do
    id "00000001-3300-4444-9999-000000000006"
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
    course_code "test-kurs"
    status "preparation"
    vimeo_id nil
    has_teleboard false
    records_released false
    url "/courses/596420be-95ec-4586-9c4c-b76b31593217"
    enrollment_delta 0
    alternative_teacher_text ""
    external_course_url ""
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

factory :amqp_user_with_fields, class: Hash do
    id "00000001-3100-4444-9999-000000000001"
    full_name "Kevin Cool Jr."
    admin false
    language "en"
    born_at "1985-04-24T00:00:00.000Z"
    created_at "2014-10-20T19:56:31.268Z"
    fields [

      {"id"=>"178fcc30-b5e8-41f7-bdb8-946c1e908cc8", "name"=>"affiliation", "title"=>{"en"=>"Affiliation"}, "type"=>"CustomTextField", "available_values"=>nil, "default_values"=>[""], "required"=>false, "values"=>["Hasso Plattner Institute"]},
      
      {"id"=>"a58626e4-9461-4e0c-bfd6-3b0c674db7db", "name"=>"country", "title"=>{"en"=>"Country"}, "type"=>"CustomSelectField", "available_values"=>["not_set", "ad", "ae", "af", "ag", "ai", "al", "am", "an", "ao", "aq", "ar", "as", "at", "au", "aw", "ax", "az", "ba", "bb", "bd", "be", "bf", "bg", "bh", "bi", "bj", "bl", "bm", "bn", "bo", "br", "bs", "bt", "bv", "bw", "by", "bz", "ca", "cc", "cd", "cf", "cg", "ch", "ci", "ck", "cl", "cm", "cn", "co", "cr", "cs", "cu", "cv", "cx", "cy", "cz", "de", "dj", "dk", "dm", "do", "dz", "ec", "ee", "eg", "eh", "er", "es", "et", "fi", "fj", "fk", "fm", "fo", "fr", "ga", "gb", "gd", "ge", "gf", "gg", "gh", "gi", "gl", "gm", "gn", "gp", "gq", "gr", "gs", "gt", "gu", "gw", "gy", "hk", "hm", "hn", "hr", "ht", "hu", "id", "ie", "il", "im", "in", "io", "iq", "ir", "is", "it", "je", "jm", "jo", "jp", "ke", "kg", "kh", "ki", "km", "kn", "kp", "kr", "kw", "ky", "kz", "la", "lb", "lc", "li", "lk", "lr", "ls", "lt", "lu", "lv", "ly", "ma", "mc", "md", "me", "mf", "mg", "mh", "mk", "ml", "mm", "mn", "mo", "mp", "mq", "mr", "ms", "mt", "mu", "mv", "mw", "mx", "my", "mz", "na", "nc", "ne", "nf", "ng", "ni", "nl", "no", "np", "nr", "nu", "nz", "om", "pa", "pe", "pf", "pg", "ph", "pk", "pl", "pm", "pn", "pr", "ps", "pt", "pw", "py", "qa", "re", "ro", "rs", "ru", "rw", "sa", "sb", "sc", "sd", "se", "sg", "sh", "si", "sj", "sk", "sl", "sm", "sn", "so", "sr", "st", "sv", "sy", "sz", "tc", "td", "tf", "tg", "th", "tj", "tk", "tl", "tm", "tn", "to", "tr", "tt", "tv", "tw", "tz", "ua", "ug", "um", "us", "uy", "uz", "va", "vc", "ve", "vg", "vi", "vn", "vu", "wf", "ws", "ye", "yt", "za", "zm", "zw", "zz"], "default_values"=>["not_set"], "required"=>false, "values"=>[""]},
      
      {"id"=>"7bee1d5d-de6a-412c-a54a-0dec94763763", "name"=>"city", "title"=>{"en"=>"City"}, "type"=>"CustomTextField", "available_values"=>nil, "default_values"=>[""], "required"=>false, "values"=>["Potsdam"]},
      
      {"id"=>"4124ffb8-fd65-45b1-80d7-af279c32bc22", "name"=>"gender", "title"=>{"en"=>"Gender"}, "type"=>"CustomSelectField", "available_values"=>["not_set", "male", "female", "other"], "default_values"=>["not_set"], "required"=>false, "values"=>["male"]}
    ]


  end

  factory :amqp_learning_room, class: Hash do
    id "ca90b0aa-d09e-499a-9afb-a462da4baa95"
    course_id "00000001-3300-4444-9999-000000000001"
    is_open true
    name "Awesome Group"
  end

  factory :amqp_learning_room_membership, class: Hash do
    id "fb526b1d-a4c8-4380-bee8-1f33fe54e660"
    collab_space_id "ca90b0aa-d09e-499a-9afb-a462da4baa95"
    status "admin"
    user_id "00000001-3100-4444-9999-000000000001"
  end

end
