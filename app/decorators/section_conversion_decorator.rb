class SectionConversionDecorator < ApplicationDecorator
  delegate_all

  def as_json(opts = {})
    {
      id: model.id,
      created_at: model.created_at,
      updated_at: model.updated_at,
      course_id: model.course_id,
      data: model.data,
    }.as_json(opts)
  end
end
