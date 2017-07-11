FactoryGirl.define do
  factory :course_statistic do
    course_id '00000001-3300-4444-9999-000000000006'

    trait :calculated do
      after(:create) do |stat|
        # We use update here so that a first version is stored by PaperTrail
        stat.update(
          course_name: 'SAP Course',
          course_status: 'active',
          no_shows: 4.0,
          total_enrollments: 200,
          enrollments_last_day: 20,
          enrollments_at_course_start: 0,
          enrollments_at_course_middle_netto: 1,
          questions: 500,
          questions_last_day: 50,
          enrollments_per_day: [0, 0, 0, 0, 0, 0, 0, 0, 0, 199],
          days_since_coursestart: 10
        )
      end
    end
  end
end