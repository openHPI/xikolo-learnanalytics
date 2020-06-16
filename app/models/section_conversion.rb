# frozen_string_literal: true

class SectionConversion < ApplicationRecord
  def calculate!
    section_conversions =
      Lanalytics::Metric::SectionConversions.query(course_id: course_id)

    update(data: section_conversions)
  end
end
