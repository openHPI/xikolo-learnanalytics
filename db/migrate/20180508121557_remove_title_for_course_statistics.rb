# frozen_string_literal: true

class RemoveTitleForCourseStatistics < ActiveRecord::Migration[4.2]
  def change
    remove_column :course_statistics, :course_name # rubocop:disable Rails/ReversibleMigration
  end
end
