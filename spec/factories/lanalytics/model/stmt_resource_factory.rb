FactoryGirl.define do

  factory :stmt_resource, class: Lanalytics::Model::Ressource do
    type "SomeResource"
    uuid "00000003-3100-4444-9999-000000000003"
    initialize_with { new(type, uuid) }
  end

end