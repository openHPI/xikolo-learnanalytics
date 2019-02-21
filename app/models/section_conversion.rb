class SectionConversion < ApplicationRecord
  has_paper_trail

  def calculate!
    section_conversions = Lanalytics::Metric::SectionConversions.query(course_id: course_id)
    update(data: section_conversions)
  end

  def created_at
    versions.first.created_at
  end

  def updated_at
    version&.created_at || versions.last.created_at
  end
end
