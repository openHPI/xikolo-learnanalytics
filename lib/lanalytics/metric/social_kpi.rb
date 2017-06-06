module Lanalytics
  module Metric
    class SocialKpi < ExpApiMetric

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)

        # calculates social kpi: social_today / avg_social

        course = Xikolo.api(:course).value!.rel(:courses).get(id: course_id).value!
        start_date = DateTime.parse(course[0].start_date)
        days_since_start = (DateTime.now.to_date - start_date.to_date).to_i

        result = {}

        if days_since_start <= 0
          result[:kpi_social] = nil
        else
          avg_social_per_day = PinboardActivity.query(nil, course_id, start_date.to_s, (start_date + days_since_start.day).to_s, nil, nil, nil)[:count].to_f / days_since_start.to_f
          social_today = PinboardActivity.query(nil, course_id, (DateTime.now - 1.day).to_s, DateTime.now.to_s, nil, nil, nil)[:count].to_f
          result[:kpi_social] = (avg_social_per_day != 0 ? social_today / avg_social_per_day : 0).round(2)
        end

        result

      end
    end
  end
end
