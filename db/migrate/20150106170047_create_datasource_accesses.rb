class CreateDatasourceAccesses < ActiveRecord::Migration[4.2]
  def change
    create_table :datasource_accesses do |t|
      t.integer :user_id
      t.integer :research_case_id
      t.string :datasource_key
      t.string :channel
      t.datetime :accessed_at, :null => false, :default => Time.now
    end
  end
end
