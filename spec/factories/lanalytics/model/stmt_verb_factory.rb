FactoryBot.define do
  factory :stmt_verb, class: Lanalytics::Model::StmtVerb do
    type { 'SOME_VERB' }
    initialize_with { new(type) }
  end
end
