# frozen_string_literal: true

##
# Report-specific configuration for custom fields from account service
#
class ProfileFieldConfiguration < ApplicationRecord
  self.table_name = 'profile_fields'

  scope :sensitive, -> { where(sensitive: true) }
  scope :omittable, -> { where(omittable: true) }

  def self.pseudonymized
    Instance.new sensitive.or(omittable)
  end

  def self.de_pseudonymized
    Instance.new omittable
  end

  class Instance
    def initialize(hidden_fields)
      @hidden_field_names = hidden_fields.pluck(:name)
    end

    def for(profile)
      ProfileFields.new(self, profile)
    end

    def all_titles
      users = Xikolo.api(:account).value!.rel(:users).get(per_page: 1).value!

      return [] if users.blank?

      ProfileFields.new(
        self, users.first.rel(:profile).get.value!
      ).titles
    end

    def hidden?(name)
      @hidden_field_names.include? name
    end
  end
end
