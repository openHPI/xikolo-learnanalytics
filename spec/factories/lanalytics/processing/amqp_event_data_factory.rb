FactoryBot.define do
  factory :amqp_user, class: Hash do
    id                { '00000001-3100-4444-9999-000000000001' }
    email             { 'kevin.cool@example.com' }
    display_name      { 'Kevin Cool' }
    first_name        { 'Kevin' }
    last_name         { 'Cool Jr.' }
    name              { 'Kevin Cool' }
    full_name         { 'Kevin Cool Jr.' }
    admin             { false }
    language          { 'en' }
    timezone          { nil }
    image_id          { nil }
    legacy_id         { nil }
    born_at           { '1985-04-24T00:00:00.000Z' }
    archived          { false }
    password_digest   { '$2a$10$v93d1K4Jw8ur/Ki0Yz69ouSnjTielvB3eb4WZJ95V6yxPZSi/rcYy' }
    created_at        { '2014-10-20T19:56:31.268Z' }
    confirmed         { true }
    emails_url        { 'http://localhost:3100/users/00000001-3100-4444-9999-000000000001/emails' }
    email_url         { 'http://localhost:3100/users/00000001-3100-4444-9999-000000000001/emails/{id}' }
    self_url          { 'http://localhost:3100/users/00000001-3100-4444-9999-000000000001' }
    blurb_url         { 'http://localhost:3100/users/00000001-3100-4444-9999-000000000001/blurb' }
    affiliated        { false }
    in_context do {
      'user_ip' => '141.89.225.126',
      'user_agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.25 Safari/537.36'
    }
    end
  end
end
