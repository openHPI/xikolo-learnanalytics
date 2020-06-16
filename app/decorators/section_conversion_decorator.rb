# frozen_string_literal: true

class SectionConversionDecorator < ApplicationDecorator
  delegate_all

  def as_json(opts = {})
    {
      id: model.id,
      updated_at: model.updated_at,
      course_id: model.course_id,
      data: model.data,
    }.as_json(opts)
  end
end
