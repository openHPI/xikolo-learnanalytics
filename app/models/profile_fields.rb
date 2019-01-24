# applies profile field configurations to user profiles from account service for reports
class ProfileFields

  def initialize(profile, deanonymized)
    @profile = profile
    @deanonymized = deanonymized
  end

  def fields
    all_fields = @profile.dig('fields') || []

    if @deanonymized
      omittable_fields = ProfileFieldConfiguration.where('omittable = true')
    else
      omittable_fields = ProfileFieldConfiguration.where('omittable = true OR sensitive = true')
    end

    omittable_fields = omittable_fields.pluck(:name)

    all_fields.reject { |f| omittable_fields.include? f['name'] }
  end

  def values
    fields.map do |f|
      f['type'] == 'CustomTextField' ? "\"#{f.dig('values', 0)}\"" : f.dig('values')&.join(';')
    end
  end

  def titles
    fields.map { |f| f.dig('title', 'en') }
  end

  def self.all_titles(deanonymized)
    users = Xikolo.api(:account).value!.rel(:users).get(per_page: 1).value!

    return [] unless users.present?

    profile = users.first.rel(:profile).get.value!
    profile_fields = ProfileFields.new(profile, deanonymized)
    profile_fields.titles
  end

end
