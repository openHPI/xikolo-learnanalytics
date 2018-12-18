module Lanalytics
  module Metric
    class ClusteringMetric < Base

      def self.datasource_keys
        [Lanalytics::Clustering::Dimensions.datasource.key]
      end

      def self.dimension_name(name)
        optional_parameter :user_id, :course_id

        @exec = proc do |params|
          Lanalytics::Clustering::Dimensions.query(
            params[:course_id],
            [name],
            [params[:user_id]].compact
          ).first[name].to_i
        end
      end

    end
  end
end
