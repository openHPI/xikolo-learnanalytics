class AddHalfGroupToTeacherAction < ActiveRecord::Migration[4.2]
  def change
    add_column :teacher_actions, :half_group, :boolean, null: false, default: false
  end
end
