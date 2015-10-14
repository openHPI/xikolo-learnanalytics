FactoryGirl.define do

  factory :stmt_resource, class: Lanalytics::Model::StmtResource do
    type "SomeResource"
    uuid "00000003-3100-4444-9999-0987654321"
    properties(propertyA: 'property1',
               propertyB: 'property2')

    initialize_with { new(type, uuid, properties) }
  end

end