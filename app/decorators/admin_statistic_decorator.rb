class AdminStatisticDecorator < ApplicationDecorator
  delegate_all

  def as_json (**opts)
    { id: model.id,
      course_code: model.course_code,

    }.as_json(**opts)
  end
end
