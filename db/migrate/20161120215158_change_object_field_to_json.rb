class ChangeObjectFieldToJson < ActiveRecord::Migration[4.2]
  def change
    remove_column :versions, :object
    add_column :versions, :object, :json
  end
end
