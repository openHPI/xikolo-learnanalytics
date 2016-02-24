class AddCourseIdToClusterGroups < ActiveRecord::Migration
  def change
    add_column :cluster_groups, :course_id, :string
  end
end
