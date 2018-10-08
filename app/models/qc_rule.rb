class QcRule < ApplicationRecord
  has_many :qc_alert
  has_many :qc_recommendations
  has_many :qc_course_statuses
  default_scope { order updated_at: :desc }

  scope :active, -> { where is_active: true }
  scope :global, -> { where is_global: true }
  scope :not_global, -> { where is_global: [nil, false] }

  def name
    worker[0..-7].underscore
  end

  def checker
    @checker ||= checker_class.new(self)
  end

  def checker_class
    Module.const_get "QcRules::#{worker[0..-7].camelize}"
  end

  def alerts_for(**attributes)
    QcAlertCollection.new(
      qc_alert.where(attributes)
    )
  end
end
