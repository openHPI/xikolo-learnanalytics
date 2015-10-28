class AddNativePostgresDatasource < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :user_uuid
      t.integer :verb_id
      t.integer :resource_id
      t.json :in_context
      t.json :with_result
      t.timestamps
    end

    create_table :verbs do |t|
      t.string :verb
      t.timestamps
    end

    create_table :resources do |t|
      t.string :uuid
      t.string :resource_type
      t.timestamps
    end
  end
end
