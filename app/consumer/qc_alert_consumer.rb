class QcAlertConsumer < Msgr::Consumer

  def destroy_course
    course_id = payload[:id]
    if course_id
      QcAlert.where(course_id: course_id).destroy_all
    end
  end

end
