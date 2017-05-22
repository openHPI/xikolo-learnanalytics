module Lanalytics
  module Metric
    class ActiveUserCountRelative < ExpApiMetric

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)

        start_time = (start_time.present? ? DateTime.parse(start_time) : (DateTime.now - 30.minutes)).to_s
        end_time = (end_time.present? ? DateTime.parse(end_time) : (DateTime.now)).to_s

        courses = Xikolo.api(:course).value!.rel(:courses).get(hidden: 'false').value!

        active_users = {}
        courses.each do |course|
          active_users[course.id] = ActiveUserCount.query(user_id, course.id, start_time, end_time, resource_id, page, per_page)
        end

        return active_users

        max_value = active_users.values.max
        min_value = active_users.values.min

        result = {}
        active_users.each do |courseid, value|
          if(max_value == 0)
            result[courseid] = 0
          elsif(max_value == min_value)
            result[courseid] = 100
          else
            result[courseid] = ((value - min_value).to_f / (max_value - min_value).to_f) * 100.0
          end
        end

        if(course_id.present?)
          result[course_id]
        else
          result
        end

        end
    end
  end
end
