class QcRule < ActiveRecord::Base
  has_many :qc_alert
  has_many :qc_recommendations
  has_many :qc_course_statuses
  default_scope { order updated_at: :desc }
end