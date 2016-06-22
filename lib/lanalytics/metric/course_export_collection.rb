module Lanalytics
  module Metric
    class CourseExportCollection
      # No support fo start and endtime yet
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        clusering_metrics = [
            'sessions',
              'average_session_duration',
              'total_session_duration',
            'forum_activity',
              'textual_forum_contribution',
              'forum_observation',
            'item_discovery',
              'video_discovery',
              'quiz_discovery',
            'video_player_activity',
            'download_activity',
            'course_performance',
            'quiz_performance',
              'ungraded_quiz_performance',
              'graded_quiz_performance',
              'main_quiz_performance',
              'bonus_quiz_performance'
        ]

        result = Lanalytics::Clustering::Dimensions.query(course_id, clusering_metrics, [user_id]).first
        result[:course_activity] = Lanalytics::Metric::CourseActivity.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)[:count].to_s
        result[:question_response_time] = Lanalytics::Metric::QuestionResponseTime.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)[:average].to_s
        result[:user_course_country] = Lanalytics::Metric::UserCourseCountry.unescaped_query(user_id, course_id, start_time, end_time, resource_id, page, per_page)

        device_usage = Lanalytics::Metric::DeviceUsage.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        device_usage_filtered = {}
        device_usage_filtered[:state] = device_usage[:behavior][:state]
        device_usage[:behavior][:usage].each do |usage|
          device_usage_filtered[usage[:category].to_sym] = usage[:total_activity].to_s
        end
        device_usage_filtered[:mobile] = "0" unless result.key? :mobile
        device_usage_filtered[:web] = "0" unless result.key? :web

        result[:device_usage] = device_usage_filtered

        result
      end

    end
  end
end
