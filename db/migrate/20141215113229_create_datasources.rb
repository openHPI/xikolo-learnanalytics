class CreateDatasources < ActiveRecord::Migration[4.2]
  def change
    create_table :datasources, id: false do |t|
      t.string :key, null: false
      t.string :name
      t.text :description
      t.text :settings
    end

    add_index :datasources, :key, unique: true
  end
end
