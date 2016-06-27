FactoryGirl.define do
  factory :test_course,  class: OpenStruct do
    start_date 1.day.ago
    end_date 1.days.from_now
    id '00000001-3100-4444-9999-000000000001'
  end
end
