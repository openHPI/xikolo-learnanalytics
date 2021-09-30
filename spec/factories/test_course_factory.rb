# frozen_string_literal: true

FactoryBot.define do
  factory :test_course, class: Hash do
    defaults = {
      'id' => '00000001-3100-4444-9999-000000000001',
      'start_date' => 1.day.ago.iso8601,
      'end_date' => 1.day.from_now.iso8601,
    }

    initialize_with { defaults.merge(attributes.stringify_keys) }
  end
end
