class AddAnnotationCode < ActiveRecord::Migration
  def change
    change_table :jobs do |t|
      t.string :annotation
    end
  end
end
