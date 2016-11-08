class ChangeObjectFieldToJson < ActiveRecord::Migration
  def change
    remove_column :versions, :object
    add_column :versions, :object, :json
  end
end
