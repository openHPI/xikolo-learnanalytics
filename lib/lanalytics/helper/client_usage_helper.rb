# frozen_string_literal: true

module Lanalytics::Helper::ClientUsageHelper
  def mobile_platforms
    [
      'android',
      'ios',
      'ios (ipad)',
      'ios (iphone)',
      'ios (ipod)',
      'windows phone',
      'blackberry',
      'firefox os',
    ]
  end

  def mobile_app_runtimes
    %w[android ios]
  end
end
