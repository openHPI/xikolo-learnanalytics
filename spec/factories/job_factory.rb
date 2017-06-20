FactoryGirl.define do
  factory :job do
    user_id 'b2157ab3-454b-0000-bb31-976b99cb016f'
    task_type 'course_export'
    task_scope ''
    status  'pending'
    job_params ''
    progress 5

    factory :course_export_job do
      task_type 'course_export'
      task_scope '5c677063-e198-4fb8-a121-aaca9482d372'
    end

    trait :pinboard_report do
      task_type 'pinboard_export'
      task_scope '4ecc3efb-bb41-4108-842d-e8b5bd8a2c16'
    end
  end
end