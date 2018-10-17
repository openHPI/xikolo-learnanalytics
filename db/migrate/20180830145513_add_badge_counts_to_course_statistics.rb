class AddBadgeCountsToCourseStatistics < ActiveRecord::Migration[4.2]
  def change
    add_column :course_statistics, :badge_issues, :integer, default: 0
    add_column :course_statistics, :badge_downloads, :integer, default: 0
    add_column :course_statistics, :badge_shares, :integer, default: 0
  end
end
