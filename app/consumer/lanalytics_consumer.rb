class LanalyticsConsumer < Msgr::Consumer

  def update

    puts "#{payload.inspect}"
    if payload[:verb] == "CREATE" or payload[:verb] == "UPDATE"
      #{:verb => "CREATE", :type => "Course", :object => {"id" => "00000001-3300-4444-9999-000000000006", "title" => "Software Profiling Future", "status" => "active", "course_code" => "sw-profiling2015", "start_date" => "2016-05-09T00:00:00.000Z", "end_date" => "2016-07-10T00:00:00.000Z", "abstract" => "This course adresses all people intered in Software Profiling.", "lang" => "en", "visual_id" => "b4d7802c-9cbb-4b65-9181-28cb547d2796", "created_at" => "2014-09-16T13:12:53.691Z", "updated_at" => "2014-09-16T13:12:53.691Z", "description_rtid" => "00000001-3700-4444-9999-000000000022", "vimeo_id" => nil, "has_teleboard" => nil, "records_released" => nil, "enrollment_delta" => 0, "alternative_teacher_text" => nil, "external_course_url" => nil, "forum_is_locked" => nil, "affiliated" => false, "external_course_delay" => 0, "hidden" => false}}
      ressource_type = payload[:ressource_type]
      ressource_uuid = payload[:ressource].with_indifferent_access[:ressource_uuid]
      #lanalytics_keys = %w(id title course_code start_date end_date)
      ressource = payload[:ressource]
      Neo4j::Session.query
        .merge(c: {ressource_type.to_sym => {ressource_uuid: ressource_uuid }})
        .on_create_set(c: ressource)
        .on_match_set(c: ressource)
        .pluck(:c)
    end

  end
end
