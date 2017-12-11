# report configuration for custom fields from account service
class ProfileFieldConfiguration < ActiveRecord::Base

  self.table_name = 'profile_fields'

  scope :sensitive, -> { where(sensitive: true) }
  scope :omittable, -> { where(omittable: true) }

end
