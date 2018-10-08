class CreateQualityControl < ActiveRecord::Migration[4.2]

  def change
    enable_extension 'uuid-ossp'

    create_table :qc_rules, id: :uuid do |t|
      t.string :worker
      t.timestamps
      t.string :status
    end

    create_table :qc_alerts, id: :uuid do|t|
      t.uuid :qc_rule_id
      t.string  :status
      t.uuid :course_id
      t.timestamps
      t.string :severity
    end

    create_table :qc_alert_statuses, id: :uuid do|t|
      t.uuid :qc_alert_id
      t.uuid :user_id
      t.boolean :ignored
      t.boolean :ack
      t.boolean :muted
      t.timestamps
    end

    create_table :qc_recommendations, id: :uuid do|t|
      t.uuid :qc_alert_id
      t.timestamps
    end

    create_table :qc_course_statuses, id: :uuid do |t|
      t.uuid :qc_rule_id
      t.uuid :course_id
      t.string :status
      t.timestamps
    end
  end
end
