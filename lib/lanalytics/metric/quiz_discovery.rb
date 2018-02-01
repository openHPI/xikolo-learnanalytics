module Lanalytics
  module Metric
    class QuizDiscovery < Base

      description 'The number of visited quizzes relative to the available ones.'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['quiz_discovery'],
          [params[:user_id]]
        ).first['quiz_discovery'].to_i
      end

    end
  end
end
