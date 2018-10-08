FactoryBot.define do
  factory :amqp_helpdesk_ticket_no_course_and_no_user, class: Hash do
    id          { '43ba0089-06db-4181-a7ee-1793daebbcaa' }
    url         { 'http://localhost:3000/courses/cloud2013/question/a63d6f40-284a-44d5-be2d-86fd44fe52dd' }
    language    { 'en' }
    mail        { 'admin@openhpi.de' }
    report      { 'qweasfaeqwedasdaew' }
    course_id   { nil }
    title       { '123123qweqweqwe' }
    data        { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.104 Safari/537.36:true:en-US' }
    user_id     {  nil }
    created_at  { '2014-10-17T20:00:24Z' }
  end
  
  factory :amqp_helpdesk_ticket_no_course_but_user, parent: :amqp_helpdesk_ticket_no_course_and_no_user do
    course_id   { nil }
    user_id     { '00000001-3100-4444-9999-000000000002' }
  end

  factory :amqp_helpdesk_ticket_course_and_user, parent: :amqp_helpdesk_ticket_no_course_and_no_user do
    course_id   { '00000001-3300-4444-9999-000000000001' }
    user_id     { '00000001-3100-4444-9999-000000000002' }
  end
end
