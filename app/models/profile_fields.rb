# frozen_string_literal: true

##
# Applies profile field configurations to user profiles from account service
# for reports.
#
class ProfileFields
  def initialize(config, profile)
    @config = config
    @profile = profile
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

  private

  def fields
    @fields ||= @profile.fetch('fields', [])
      .reject {|f| @config.hidden? f['name'] }
  end

  def value(from_field:)
    if from_field['type'] == 'CustomTextField'
      "\"#{from_field.dig('values', 0)}\""
    else
      from_field['values']&.join(';')
    end
  end
end
