class AddHalfGroupToTeacherAction < ActiveRecord::Migration
  def change
    add_column :teacher_actions, :half_group, :boolean, null: false, default: false
  end
end
