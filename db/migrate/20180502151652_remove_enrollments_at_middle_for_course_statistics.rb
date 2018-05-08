class RemoveEnrollmentsAtMiddleForCourseStatistics < ActiveRecord::Migration
  def change
    remove_column :course_statistics, :enrollments_at_course_middle
  end
end
