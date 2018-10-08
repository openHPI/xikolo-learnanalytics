class QcCourseStatusDecorator< ApplicationDecorator
  delegate_all

  def as_json(opts = {})
    { id: model.id,
      qc_rule_id: model.qc_rule_id,
      course_id: model.course_id,
      status: model.status,
    }.as_json(opts)
  end
end