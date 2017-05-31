FactoryGirl.define do
  factory :job do
    user_id 'b2157ab3-454b-0000-bb31-976b99cb016f'
    task_type 'course_export'
    task_scope ''
    status  'pending'
    job_params ''
    file_id 'b2147ab3-424b-4777-bb31-976b99cb016f'
    file_expire_date 1.day.from_now
    progress 5

    factory :course_export_job do
      task_type 'course_export'
      task_scope '5c677063-e198-4fb8-a121-aaca9482d372'
    end
  end
end