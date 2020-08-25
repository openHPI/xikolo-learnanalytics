# frozen_string_literal: true

##
# Report-specific configuration for custom fields from account service
#
class ProfileFieldConfiguration < ApplicationRecord
  self.table_name = 'profile_fields'

  scope :sensitive, -> { where(sensitive: true) }
  scope :omittable, -> { where(omittable: true) }
end
