class RemoveEnrollmentsAtMiddleForCourseStatistics < ActiveRecord::Migration[4.2]
  def change
    remove_column :course_statistics, :enrollments_at_course_middle
  end
end
