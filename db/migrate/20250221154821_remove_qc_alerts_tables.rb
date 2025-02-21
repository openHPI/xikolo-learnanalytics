# frozen_string_literal: true

class RemoveQcAlertsTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :qc_rules if table_exists?(:qc_rules)
    drop_table :qc_alert_statuses if table_exists?(:qc_alert_statuses)
    drop_table :qc_course_statuses if table_exists?(:qc_course_statuses)
    drop_table :qc_recommendations if table_exists?(:qc_recommendations)
    drop_table :qc_alerts if table_exists?(:qc_alerts)
  end
end
