require 'msgr'


message = {id: "5eabdf59-d754-4e50-9c21-d002a3710da5", title: "Mumap Gerardp 123123123", start_date: nil, display_start_date: nil, end_date: nil, abstract: "", description_rtid: "848a1364-c3d7-440d-bc28-cb7790b7c07d", visual_id: nil, lang: "de", categories: [], teacher_ids: [], teaching_team_ids: [], course_code: "muma", status: "preparation", vimeo_id: nil, has_teleboard: false, records_released: false, url: "/courses/5eabdf59-d754-4e50-9c21-d002a3710da5", enrollment_delta: 0, alternative_teacher_text: "", external_course_url: "", external_course_delay: 0, forum_is_locked: false, affiliated: false, hidden: false, welcome_mail: ""}


10000.times do |i|
  message[:title] = "Muma-Papa-Gerardo #{i}"
  Msgr.publish(message, to: 'xikolo.course.course.update')
end
