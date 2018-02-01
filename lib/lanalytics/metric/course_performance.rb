module Lanalytics
  module Metric
    class CoursePerformance < Base

      description 'Achieved course performance (points achieved / max points).'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['course_performance'],
          [params[:user_id]]
        ).first['course_performance'].to_i
      end

    end
  end
end
