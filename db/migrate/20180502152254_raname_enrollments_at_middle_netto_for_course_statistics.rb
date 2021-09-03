# frozen_string_literal: true

class RanameEnrollmentsAtMiddleNettoForCourseStatistics < ActiveRecord::Migration[4.2]
  def change
    rename_column :course_statistics, :enrollments_at_course_middle_netto, :enrollments_at_course_middle
  end
end
