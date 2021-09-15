# frozen_string_literal: true

class AddCourseIdToClusterGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :cluster_groups, :course_id, :string
  end
end
