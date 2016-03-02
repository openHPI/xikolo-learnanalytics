class ClusterGroup < ActiveRecord::Base
  has_many :teacher_actions

  validates_presence_of :name, :user_uuids, :cluster_results
end
