# frozen_string_literal: true

FactoryBot.define do
  factory :report_job do
    user_id     { 'b2157ab3-454b-0000-bb31-976b99cb016f' }
    task_type   { 'course_report' }
    task_scope  { 'foobar' }
    status      { 'requested' }
    job_params  { '' }
    progress    { 5 }
    error_text  { nil }

    trait :course_report do
      task_type   { 'course_report' }
      task_scope  { '5c677063-e198-4fb8-a121-aaca9482d372' }
    end

    trait :combined_course_report do
      task_type   { 'combined_course_report' }
      task_scope  { '5c677063-e198-4fb8-a121-aaca9482d372' }
    end

    trait :course_events_report do
      task_type   { 'course_events_report' }
      task_scope  { '5c677063-e198-4fb8-a121-aaca9482d372' }
    end

    trait :user_report do
      task_type   { 'user_report' }
      task_scope  { nil }
    end

    trait :unconfirmed_user_report do
      task_type   { 'unconfirmed_user_report' }
      task_scope  { nil }
    end

    trait :submission_report do
      task_type   { 'submission_report' }
      task_scope  { '4ecc3efb-bb41-4108-842d-e8b5bd8a2c16' }
    end

    trait :pinboard_report do
      task_type   { 'pinboard_report' }
      task_scope  { '4ecc3efb-bb41-4108-842d-e8b5bd8a2c16' }
    end

    trait :enrollment_statistics_report do
      task_type   { 'enrollment_statistics_report' }
      task_scope  { '4ecc3efb-bb41-4108-842d-e8b5bd8a2c16' }
    end

    trait :course_content_report do
      task_type   { 'course_content_report' }
      task_scope  { '4ecc3efb-bb41-4108-842d-e8b5bd8a2c16' }
    end

    trait :overall_course_summary_report do
      task_type   { 'overall_course_summary_report' }
      task_scope  { nil }
    end

    trait :openwho_course_report do
      task_type   { 'openwho_course_report' }
      task_scope  { '5c677063-e198-4fb8-a121-aaca9482d372' }
    end

    trait :openwho_combined_course_report do
      task_type   { 'openwho_combined_course_report' }
      task_scope  { '5c677063-e198-4fb8-a121-aaca9482d372' }
    end
  end
end
