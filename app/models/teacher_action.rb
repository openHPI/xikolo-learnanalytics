class TeacherAction < ApplicationRecord
  belongs_to :cluster_group

  validates_presence_of :cluster_group, :user_uuids, :action_performed_at

  scope :half_group, -> { where half_group: true }
end
