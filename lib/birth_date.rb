# frozen_string_literal: true

class BirthDate
  def initialize(birth_date)
    @birth_date = from birth_date
  end

  def age_group_at(current_date)
    case age_at(current_date)
      when 0...20
        '<20'
      when 20...30
        '20-29'
      when 30...40
        '30-39'
      when 40...50
        '40-49'
      when 50...60
        '50-59'
      when 60...70
        '60-69'
      when (70..)
        '70+'
      else
        ''
    end
  end
  # rubocop:enable all

  private

  def from(date)
    return if date.blank?

    parsed = DateTime.parse(date)

    parsed if parsed.year <= DateTime.now.year
  end

  # Not to add 1 year to the age of users whose birthday is not yet reached
  # in current year, it also checks if the user's birthday has yet to arrive
  # and, in that case, it subtracts 1 to the difference
  # between current year and user's birth year.
  def age_at(current_date)
    return if @birth_date.blank? || current_date.blank?

    current_date.year - @birth_date.year - year_offset(current_date)
  end

  def year_offset(date)
    upcoming_birth_day?(date) ? 1 : 0
  end

  def upcoming_birth_day?(date)
    date.month < @birth_date.month ||
      (date.month == @birth_date.month && date.day < @birth_date.day)
  end
end
