class AddTypeToDatasources < ActiveRecord::Migration
  def change
    add_column :datasources, :type, :string
  end
end
