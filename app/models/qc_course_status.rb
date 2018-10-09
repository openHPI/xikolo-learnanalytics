class QcCourseStatus < ApplicationRecord
  belongs_to :qc_rules, optional: true
end