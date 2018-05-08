class RanameEnrollmentsAtMiddleNettoForCourseStatistics < ActiveRecord::Migration
  def change
    rename_column :course_statistics, :enrollments_at_course_middle_netto, :enrollments_at_course_middle
  end
end
