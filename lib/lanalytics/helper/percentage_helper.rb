# frozen_string_literal: true

module Lanalytics::Helper::PercentageHelper
end

class Numeric
  def percent_of(n)
    (to_f / n.to_f * 100.0).round(2)
  end
end
