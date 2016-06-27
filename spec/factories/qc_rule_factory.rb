FactoryGirl.define do
  factory :qc_rule do
    worker 'PinboardActivityWorker'
    is_active false
  end
end