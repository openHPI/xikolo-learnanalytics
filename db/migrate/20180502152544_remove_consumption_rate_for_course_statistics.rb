# frozen_string_literal: true

class RemoveConsumptionRateForCourseStatistics < ActiveRecord::Migration[4.2]
  def change
    remove_column :course_statistics, :consumption_rate # rubocop:disable Rails/ReversibleMigration
  end
end
