# frozen_string_literal: true

class AddEnrollmentStatsToCourseStatistics < ActiveRecord::Migration[4.2]
  # rubocop:disable Rails/BulkChangeTable
  def change
    add_column :course_statistics, :enrollments_at_course_start_netto, :integer
    add_column :course_statistics, :enrollments_at_course_middle_netto, :integer
    add_column :course_statistics, :enrollments_at_course_end_netto, :integer

    add_column :course_statistics, :shows, :integer
    add_column :course_statistics, :shows_at_middle, :integer
    add_column :course_statistics, :shows_at_end, :integer

    change_column :course_statistics, :no_shows, :integer
    add_column :course_statistics, :no_shows_at_middle, :integer
    add_column :course_statistics, :no_shows_at_end, :integer
  end
  # rubocop:enable all
end
