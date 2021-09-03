# frozen_string_literal: true

class RemoveEnrollmentsAtMiddleForCourseStatistics < ActiveRecord::Migration[4.2]
  def change
    remove_column :course_statistics, :enrollments_at_course_middle # rubocop:disable Rails/ReversibleMigration
  end
end
