# frozen_string_literal: true

module Lanalytics
  module Metric
    class SocialKpi < ExpEventsElasticMetric
      description 'Calculates social kpi: social_today / avg_social.'

      required_parameter :course_id

      exec do |params|
        course_id = params[:course_id]

        course = Restify.new(:course).get.value!
          .rel(:courses).get(id: course_id).value!
        start_date = DateTime.parse(course[0]['start_date'])
        days_since_start = (DateTime.now.to_date - start_date.to_date).to_i

        result = {}

        if days_since_start <= 0
          result[:kpi_social] = nil
        else
          avg_social_per_day = PinboardActivity.query(
            course_id:,
            start_date: start_date.to_s,
            end_date: (start_date + days_since_start.day).to_s,
          )[:count].to_f / days_since_start.to_f
          social_today = PinboardActivity.query(
            course_id:,
            start_date: (DateTime.now - 1.day).to_s,
            end_date: DateTime.now.to_s,
          )[:count].to_f
          result[:kpi_social] = (avg_social_per_day.zero? ? 0 : social_today / avg_social_per_day).round(2)
        end

        result
      end
    end
  end
end
