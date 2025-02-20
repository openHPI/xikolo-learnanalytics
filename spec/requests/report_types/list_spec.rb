# frozen_string_literal: true

require 'spec_helper'

describe 'ReportTypes: List' do
  subject(:resource) { api.rel(:report_types).get.value! }

  before { Lanalytics.config.merge YAML.safe_load report_types }

  let(:api) { Restify.new(:test).get.value! }

  let(:course_report) do
    {
      'type' => 'course_report',
      'name' => 'Course Report',
      'description' => 'This report includes data about each enrollment of a course.',
      'scope' => {
        'type' => 'select',
        'name' => 'task_scope',
        'label' => 'Select a course:',
        'values' => 'courses',
        'options' => {
          'prompt' => 'Please select...',
          'disabled' => '',
          'required' => true,
        },
      },
      'options' => [
        {
          'type' => 'checkbox',
          'name' => 'machine_headers',
          'label' => 'Better machine-readable headers (lowercase and underscored).',
        },
        {
          'type' => 'checkbox',
          'name' => 'de_pseudonymized',
          'label' => 'De-pseudonymize report. Attention! Only use this option if the further processing of the data is in compliance with the data protection regulations of the platform.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_access_groups',
          'label' => "Include data about the users' memberships in configured access groups.",
        },
        {
          'type' => 'checkbox',
          'name' => 'include_profile',
          'label' => 'Include additional profile data. Sensitive data is omitted if pseudonymized.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_auth',
          'label' => 'Include certain configured authorization attributes of users (de-pseudonymization required).',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_analytics_metrics',
          'label' => 'Include learning analytics metrics. This can significantly increase the time to create the report.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_all_quizzes',
          'label' => 'Include all quizzes.',
        },
        {
          'type' => 'text_field',
          'name' => 'zip_password',
          'label' => 'Optional password for the generated ZIP archive:',
          'options' => {
            'placeholder' => 'Password',
            'input_size' => 'large',
          },
        },
      ],
    }
  end

  let(:combined_course_report) do
    {
      'type' => 'combined_course_report',
      'name' => 'Combined Course Report',
      'description' => 'This report combines multiple course reports which are tagged with the same selected classifier.',
      'scope' => {
        'type' => 'select',
        'name' => 'task_scope',
        'label' => 'Select a classifier:',
        'values' => 'classifiers',
        'options' => {
          'prompt' => 'Please select...',
          'disabled' => '',
          'required' => true,
        },
      },
      'options' => [
        {
          'type' => 'checkbox',
          'name' => 'machine_headers',
          'label' => 'Better machine-readable headers (lowercase and underscored).',
        },
        {
          'type' => 'checkbox',
          'name' => 'de_pseudonymized',
          'label' => 'De-pseudonymize report. Attention! Only use this option if the further processing of the data is in compliance with the data protection regulations of the platform.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_access_groups',
          'label' => "Include data about the users' memberships in configured access groups.",
        },
        {
          'type' => 'checkbox',
          'name' => 'include_profile',
          'label' => 'Include additional profile data. Sensitive data is omitted if pseudonymized.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_auth',
          'label' => 'Include certain configured authorization attributes of users (de-pseudonymization required).',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_analytics_metrics',
          'label' => 'Include learning analytics metrics. This can significantly increase the time to create the report.',
        },
        {
          'type' => 'text_field',
          'name' => 'zip_password',
          'label' => 'Optional password for the generated ZIP archive:',
          'options' => {
            'placeholder' => 'Password',
            'input_size' => 'large',
          },
        },
      ],
    }
  end

  let(:user_report) do
    {
      'type' => 'user_report',
      'name' => 'User Report',
      'description' => 'This report includes data about each registered and confirmed user of the platform.',
      'options' => [
        {
          'type' => 'checkbox',
          'name' => 'machine_headers',
          'label' => 'Better machine-readable headers (lowercase and underscored).',
        },
        {
          'type' => 'checkbox',
          'name' => 'de_pseudonymized',
          'label' => 'De-pseudonymize report. Attention! Only use this option if the further processing of the data is in compliance with the data protection regulations of the platform.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_top_location',
          'label' => 'Include the top country and top city for every user.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_access_groups',
          'label' => "Include data about the users' memberships in configured access groups.",
        },
        {
          'type' => 'checkbox',
          'name' => 'include_profile',
          'label' => 'Include additional profile data. Sensitive data is omitted if pseudonymized.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_auth',
          'label' => 'Include certain configured authorization attributes of users (de-pseudonymization required).',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_consents',
          'label' => "Include the user's given consents.",
        },
        {
          'type' => 'checkbox',
          'name' => 'include_features',
          'label' => 'Include data if the user has certain configured features enabled.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_email_subscriptions',
          'label' => 'Include data if the user subscribed to email announcements.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_last_activity',
          'label' => "Include the timestamp of the user's last activity.",
        },
        {
          'type' => 'checkbox',
          'name' => 'include_enrollment_evaluation',
          'label' => 'Include enrollment evaluation for all courses for every user. This can significantly increase the time to create the report.',
        },
        {
          'type' => 'checkbox',
          'name' => 'combine_enrollment_info',
          'label' => 'Combine enrollment evaluation data.',
        },
        {
          'type' => 'text_field',
          'name' => 'zip_password',
          'label' => 'Optional password for the generated ZIP archive:',
          'options' => {
            'placeholder' => 'Password',
            'input_size' => 'large',
          },
        },
      ],
    }
  end

  let(:unconfirmed_user_report) do
    {
      'type' => 'unconfirmed_user_report',
      'name' => 'Unconfirmed User Report',
      'description' => 'This report includes identifiable data about each registered but unconfirmed user of the platform. Attention! Only generate this report if the further processing of the data is in compliance with the data protection regulations of the platform.',
      'options' => [
        {
          'type' => 'checkbox',
          'name' => 'machine_headers',
          'label' => 'Better machine-readable headers (lowercase and underscored).',
        },
        {
          'type' => 'text_field',
          'name' => 'zip_password',
          'label' => 'Optional password for the generated ZIP archive:',
          'options' => {
            'placeholder' => 'Password',
            'input_size' => 'large',
          },
        },
      ],
    }
  end

  let(:submission_report) do
    {
      'type' => 'submission_report',
      'name' => 'Quiz Submissions Report',
      'description' => 'This report includes data about each submission of a quiz.',
      'scope' => {
        'type' => 'text_field',
        'name' => 'task_scope',
        'label' => 'Enter a Quiz ID (the Content ID of the item):',
        'options' => {'placeholder' => 'Quiz ID', 'input_size' => 'large', 'required' => true},
      },
      'options' => [
        {
          'type' => 'checkbox',
          'name' => 'machine_headers',
          'label' => 'Better machine-readable headers (lowercase and underscored).',
        },
        {
          'type' => 'checkbox',
          'name' => 'de_pseudonymized',
          'label' => 'De-pseudonymize report. Attention! Only use this option if the further processing of the data is in compliance with the data protection regulations of the platform.',
        },
        {
          'type' => 'text_field',
          'name' => 'zip_password',
          'label' => 'Optional password for the generated ZIP archive:',
          'options' => {
            'placeholder' => 'Password',
            'input_size' => 'large',
          },
        },
      ],
    }
  end

  let(:pinboard_report) do
    {
      'type' => 'pinboard_report',
      'name' => 'Course Pinboard Report',
      'description' => 'This report includes data about each forum post of a course.',
      'scope' => {
        'type' => 'select',
        'name' => 'task_scope',
        'label' => 'Select a course:',
        'values' => 'courses',
        'options' => {
          'prompt' => 'Please select...',
          'disabled' => '',
          'required' => true,
        },
      },
      'options' => [
        {
          'type' => 'checkbox',
          'name' => 'machine_headers',
          'label' => 'Better machine-readable headers (lowercase and underscored).',
        },
        {
          'type' => 'checkbox',
          'name' => 'de_pseudonymized',
          'label' => 'De-pseudonymize report. Attention! Only use this option if the further processing of the data is in compliance with the data protection regulations of the platform.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_collab_spaces',
          'label' => 'Include collab spaces.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_permission_groups',
          'label' => "Include the user's global and course permission groups.",
        },
        {
          'type' => 'text_field',
          'name' => 'zip_password',
          'label' => 'Optional password for the generated ZIP archive:',
          'options' => {
            'placeholder' => 'Password',
            'input_size' => 'large',
          },
        },
      ],
    }
  end

  let(:enrollment_statistics_report) do
    {
      'type' => 'enrollment_statistics_report',
      'name' => 'Enrollment Statistics Report',
      'description' => 'This report includes the total enrollments count and unique enrolled users count for a given timeframe.',
      'options' => [
        {
          'type' => 'checkbox',
          'name' => 'machine_headers',
          'label' => 'Better machine-readable headers (lowercase and underscored).',
        },
        {
          'type' => 'date_field',
          'name' => 'first_date',
          'options' => {'min' => '2013-01-01', 'required' => true},
          'label' => 'First date:',
        },
        {
          'type' => 'date_field',
          'name' => 'last_date',
          'options' => {'min' => '2013-01-01', 'required' => true},
          'label' => 'Last date:',
        },
        {
          'type' => 'radio_group',
          'name' => 'window_unit',
          'values' => {'days' => 'Days', 'months' => 'Months (the day input fields are ignored)'},
          'label' => 'Unit of time window:',
        },
        {
          'type' => 'number_field',
          'name' => 'window_size',
          'options' => {'value' => 1, 'min' => 1, 'input_size' => 'extra-small'},
          'label' => 'Length of time window:',
        },
        {
          'type' => 'checkbox',
          'name' => 'sliding_window',
          'label' => 'Sliding window instead of fixed interval.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_all_classifiers',
          'label' => 'Include a filtered report for all defined course classifiers.',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_active_users',
          'label' => 'Include active users (experimental analytics metric).',
        },
        {
          'type' => 'text_field',
          'name' => 'zip_password',
          'label' => 'Optional password for the generated ZIP archive:',
          'options' => {
            'placeholder' => 'Password',
            'input_size' => 'large',
          },
        },
      ],
    }
  end

  let(:course_events_report) do
    {
      'type' => 'course_events_report',
      'name' => 'Course Events Report',
      'description' => 'This report includes data about each learning analytics event of a course. The course must have a start and end date.',
      'scope' => {
        'type' => 'select',
        'name' => 'task_scope',
        'label' => 'Select a course:',
        'values' => 'courses',
        'options' => {
          'prompt' => 'Please select...',
          'disabled' => '',
          'required' => true,
        },
      },
      'options' => [
        {
          'type' => 'checkbox',
          'name' => 'machine_headers',
          'label' => 'Better machine-readable headers (lowercase and underscored).',
        },
        {
          'type' => 'checkbox',
          'name' => 'de_pseudonymized',
          'label' => 'De-pseudonymize report. Attention! Only use this option if the further processing of the data is in compliance with the data protection regulations of the platform.',
        },
        {
          'type' => 'text_field',
          'name' => 'verb',
          'label' => 'Optional event filter based on the verb field, the wildcard operators ? and * are supported:',
          'options' => {'placeholder' => 'Verb', 'input_size' => 'large'},
        },
        {
          'type' => 'text_field',
          'name' => 'zip_password',
          'label' => 'Optional password for the generated ZIP archive:',
          'options' => {
            'placeholder' => 'Password',
            'input_size' => 'large',
          },
        },
      ],
    }
  end

  let(:course_content_report) do
    {
      'type' => 'course_content_report',
      'name' => 'Course Content Report',
      'description' => 'This report includes data about each learning item of a course.',
      'scope' => {
        'type' => 'select',
        'name' => 'task_scope',
        'label' => 'Select a course:',
        'values' => 'courses',
        'options' => {
          'prompt' => 'Please select...',
          'disabled' => '',
          'required' => true,
        },
      },
      'options' => [
        {
          'type' => 'checkbox',
          'name' => 'machine_headers',
          'label' => 'Better machine-readable headers (lowercase and underscored).',
        },
        {
          'type' => 'text_field',
          'name' => 'zip_password',
          'label' => 'Optional password for the generated ZIP archive:',
          'options' => {
            'placeholder' => 'Password',
            'input_size' => 'large',
          },
        },
      ],
    }
  end

  let(:overall_course_summary_report) do
    {
      'type' => 'overall_course_summary_report',
      'name' => 'Overall Course Summary Report',
      'description' => 'This report includes data about each course of the platform.',
      'options' => [
        {
          'type' => 'checkbox',
          'name' => 'machine_headers',
          'label' => 'Better machine-readable headers (lowercase and underscored).',
        },
        {
          'type' => 'checkbox',
          'name' => 'include_statistics',
          'label' => 'Include course statistics.',
        },
        {
          'type' => 'date_field',
          'name' => 'end_date',
          'options' => {'min' => '2013-01-01'},
          'label' => 'Optional latest date for statistics:',
        },
        {
          'type' => 'text_field',
          'name' => 'zip_password',
          'label' => 'Optional password for the generated ZIP archive:',
          'options' => {
            'placeholder' => 'Password',
            'input_size' => 'large',
          },
        },
      ],
    }
  end

  context 'empty config' do
    let(:report_types) do
      <<~YML
        reports: ~
      YML
    end

    it { expect(resource).to eq [] }
  end

  context 'general reports' do
    let(:report_types) do
      <<~YML
        reports:
          types:
            - course_report
            - combined_course_report
            - user_report
            - unconfirmed_user_report
            - submission_report
            - pinboard_report
            - enrollment_statistics_report
            - course_events_report
            - course_content_report
            - overall_course_summary_report
      YML
    end

    it { expect(resource).to have(10).items }
    it { expect(resource).to include course_report }
    it { expect(resource).to include combined_course_report }
    it { expect(resource).to include user_report }
    it { expect(resource).to include unconfirmed_user_report }
    it { expect(resource).to include submission_report }
    it { expect(resource).to include pinboard_report }
    it { expect(resource).to include enrollment_statistics_report }
    it { expect(resource).to include course_events_report }
    it { expect(resource).to include course_content_report }
    it { expect(resource).to include overall_course_summary_report }
  end
end
