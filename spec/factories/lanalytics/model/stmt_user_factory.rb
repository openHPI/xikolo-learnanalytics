FactoryBot.define do
  factory :stmt_user, class: Lanalytics::Model::StmtUser do
    uuid { '00000003-3100-4444-9999-1234567890' }
    initialize_with { new(uuid) }
  end
end
