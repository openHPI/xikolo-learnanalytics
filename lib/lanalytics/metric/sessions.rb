module Lanalytics
  module Metric
    class Sessions < Base

      description 'The number of consecutive event streams where individual events have no wider gap than 30 minutes.'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['sessions'],
          [params[:user_id]]
        ).first['sessions'].to_i
      end

    end
  end
end
