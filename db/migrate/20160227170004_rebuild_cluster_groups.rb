class RebuildClusterGroups < ActiveRecord::Migration
  def change
    if ActiveRecord::Base.connection.table_exists? 'cluster_groups'
      drop_table :cluster_groups
    end

    create_table :cluster_groups, id: :uuid do |t|
      t.string :name
      t.jsonb :user_uuids
      t.jsonb :cluster_results
      t.uuid :course_id
      t.timestamps
    end
  end
end
