class AddHalfGroupToTeacherAction < ActiveRecord::Migration
  def change
    add_column :teacher_actions, :half_group, :boolean
  end
end
