FactoryBot.define do

  factory :amqp_exp_stmt, class: Hash do
    user({type: :USER, uuid: "00000001-3100-4444-9999-000000000002"})
    verb({type: :VIDEO_PLAY})
    resource(type: :ITEM, uuid: "00000003-3100-4444-9999-000000000002")
    timestamp "2014-10-27T14:59:08+01:00"
    with_result({})
    in_context("currentTime"=>"67.698807", "currentSpeed"=>"1")
  end

end
