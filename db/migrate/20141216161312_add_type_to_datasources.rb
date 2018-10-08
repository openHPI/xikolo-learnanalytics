class AddTypeToDatasources < ActiveRecord::Migration[4.2]
  def change
    add_column :datasources, :type, :string
  end
end
