FactoryBot.define do
  factory :qc_alert_status do
    user_id     { '00000001-3100-4444-9999-000000000002' }
    qc_alert_id { 'b2157ab3-454b-0000-bb31-976b99cb016f' }
    ignored     { 'true' }
  end
end
