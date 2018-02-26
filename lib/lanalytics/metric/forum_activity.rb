module Lanalytics
  module Metric
    class ForumActivity < Base

      description 'The sum of textual forum contribution and forum observation.'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['forum_activity'],
          [params[:user_id]]
        ).first['forum_activity'].to_i
      end

    end
  end
end
