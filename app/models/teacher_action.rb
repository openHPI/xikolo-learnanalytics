class TeacherAction < ActiveRecord::Base
  belongs_to :cluster_group

  validates_presence_of :cluster_group, :user_uuids, :action_performed_at
end
