module Lanalytics
  module Metric
    class ItemDiscovery < Base

      description 'The number of visited items relative to the available ones. Visited means a single click on the item.'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['item_discovery'],
          [params[:user_id]]
        ).first['item_discovery'].to_i
      end

    end
  end
end
