class AddNativePostgresDatasource < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :user_uuid
      t.string :verb_id
      t.string :resource_id
      t.json :in_context
      t.json :with_result
      t.timestamps
    end

    create_table :verbs do |t|
      t.string :verb
      t.timestamps
    end

    create_table :resources do |t|
      t.string :resource_uuid
      t.string :type
      t.timestamps
    end
  end
end
