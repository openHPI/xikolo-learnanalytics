class FixVersions < ActiveRecord::Migration[5.2]
  def up
    remove_column :versions, :item_id
    add_column :versions, :item_id, :uuid

    execute <<-SQL
      DELETE FROM versions WHERE object IS NULL;
      UPDATE versions SET item_id = (object->>'id')::UUID;
    SQL

    change_column_null :versions, :item_id, false
    add_index :versions, %i[item_type item_id]
  end
end
