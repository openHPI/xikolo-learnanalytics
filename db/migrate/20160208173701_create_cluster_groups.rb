class CreateClusterGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :cluster_groups do |t|
      t.string :name
      t.string :user_uuids
      t.jsonb :cluster_results
      t.timestamps
    end
  end
end
