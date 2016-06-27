class AddJob < ActiveRecord::Migration

  def change
    enable_extension 'uuid-ossp'
    create_table :jobs, id: :uuid do |t|
      t.string  :task_type
      t.string  :task_scope
      t.string  :status
      t.string  :job_params
      t.timestamps
      t.uuid  :user_id
      t.uuid  :file_id
      t.datetime  :file_expire_date
      t.integer :progress

    end
  end
end
