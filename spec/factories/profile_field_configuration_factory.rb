# frozen_string_literal: true

FactoryBot.define do
  factory :profile_field_configuration do
    name      { 'city' }
    sensitive { false }
    omittable { false }
  end
end
