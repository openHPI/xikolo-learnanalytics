require 'date'

FactoryBot.define do

  factory :stmt, class: Lanalytics::Model::ExpApiStatement do
    association :user, factory: :stmt_user, strategy: :build
    association :verb, factory: :stmt_verb, strategy: :build
    association :resource, factory: :stmt_resource, strategy: :build
    timestamp DateTime.parse('8 May 1989 05:00:00') # Gerardo's birthday, I need a little bit of love ;-D
    with_result result: 1000
    in_context location: 'Potsdam'

    initialize_with { new(user, verb, resource, timestamp, with_result, in_context) }
  end

end