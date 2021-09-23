# frozen_string_literal: true

FactoryBot.define do
  factory :qc_alert do
    qc_rule_id  { 'b2157ab3-454b-0000-bb31-976b99cb016f' }
    course_id   { '00000001-3300-4444-9999-000000000001' }
    severity    { 'low' }
    annotation  { '' }
    status      { 'open' }

    trait :other_course do
      course_id { '00000001-3300-4444-9999-000000000002' }
    end
  end
end
