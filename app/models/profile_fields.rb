# frozen_string_literal: true

##
# Applies profile field configurations to user profiles from account service
# for reports.
#
class ProfileFields
  def initialize(profile, deanonymized)
    @profile = profile
    @deanonymized = deanonymized
  end

  def [](name)
    field = fields.find {|f| f['name'] == name }

    return nil unless field

    value(from_field: field)
  end

  def values
    fields.map {|field| value(from_field: field) }
  end

  def titles
    fields.map {|f| f.dig('title', 'en') }
  end

  def self.all_titles(deanonymized)
    users = Xikolo.api(:account).value!.rel(:users).get(per_page: 1).value!

    return [] if users.blank?

    profile = users.first.rel(:profile).get.value!
    profile_fields = ProfileFields.new(profile, deanonymized)
    profile_fields.titles
  end

  private

  def fields
    @fields ||= @profile.fetch('fields', [])
      .reject {|f| hidden_fields.include? f['name'] }
  end

  ##
  # The names of the fields that should not be exposed.
  #
  def hidden_fields
    @hidden_fields ||= if @deanonymized
                         ProfileFieldConfiguration.where('omittable = true')
                       else
                         ProfileFieldConfiguration
                           .where('omittable = true OR sensitive = true')
                       end.pluck(:name)
  end

  def value(from_field:)
    if from_field['type'] == 'CustomTextField'
      "\"#{from_field.dig('values', 0)}\""
    else
      from_field.dig('values')&.join(';')
    end
  end
end
