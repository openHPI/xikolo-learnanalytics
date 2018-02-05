FactoryBot.define do

  factory :amqp_exp_stmt, class: Hash do
    user({type: :USER, uuid: "00000001-3100-4444-9999-000000000002"})
    verb({type: :VIDEO_PLAY})
    resource(type: :ITEM, uuid: "00000003-3100-4444-9999-000000000002")
    timestamp "2014-10-27T14:59:08+01:00"
    with_result({})
    in_context("currentTime"=>"67.698807",
               "currentSpeed"=>"1",
               "courseId"=>"00000002-3100-4444-9999-000000000002",
               "user_ip"=>"141.89.225.126",
               "user_agent"=>"Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36",
               "user_location_country_code"=>"DE",
               "user_location_city"=>"Potsdam",
               "screen_width"=>"1920",
               "screen_height"=>"1080")
  end

end
