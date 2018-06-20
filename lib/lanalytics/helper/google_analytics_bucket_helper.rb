module Lanalytics::Helper::GoogleAnalyticsBucketHelper
  def self.histogram_bucket_labels(bucket_boundaries)
    labels = bucket_boundaries.map.with_index do |boundary, index|
      if index == bucket_boundaries.size - 1
        "#{boundary}+"
      elsif bucket_boundaries[index + 1] - boundary > 1
        next_boundary = bucket_boundaries[index + 1]
        "#{boundary}-#{next_boundary - 1}"
      else
        boundary.to_s
      end
    end
    if bucket_boundaries.first > 0
      labels.unshift "<#{bucket_boundaries.first}"
    end

    labels
  end
end