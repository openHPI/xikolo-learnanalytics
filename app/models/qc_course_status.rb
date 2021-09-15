# frozen_string_literal: true

class QcCourseStatus < ApplicationRecord
  belongs_to :qc_rule, optional: true
end
