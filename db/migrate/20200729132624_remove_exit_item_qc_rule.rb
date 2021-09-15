# frozen_string_literal: true

class RemoveExitItemQcRule < ActiveRecord::Migration[5.2]
  class QcRule < ActiveRecord::Base; end

  class QcCourseStatus < ActiveRecord::Base; end

  class QcAlert < ActiveRecord::Base; end

  class QcAlertStatus < ActiveRecord::Base; end

  class QcRecommendation < ActiveRecord::Base; end

  def up
    rules = QcRule.where(worker: 'ExitItemWorker')

    rules.find_each do |rule|
      QcCourseStatus.where(qc_rule_id: rule.id).delete_all

      alerts = QcAlert.where(qc_rule_id: rule.id)

      alerts.find_each do |alert|
        QcAlertStatus.where(qc_alert_id: alert.id).delete_all
        QcRecommendation.where(qc_alert_id: alert.id).delete_all
      end

      alerts.delete_all
    end

    rules.delete_all
  end
end
