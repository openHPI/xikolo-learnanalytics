module Lanalytics
  module Metric
    class LearnerDashboardLinkCounts < ExpApiMetric

      description 'Counts the number of clicks on links (to forum, items, sections) in the learner dashboard.'

      optional_parameter :user_id, :course_id, :start_date, :end_date

      exec do |params|
        {
          ld_dates_visit: count_for_verb(params, 'ld_dates_visit'),
          ld_pinboard_forum_visit: count_for_verb(params, 'ld_pinboard_forum_visit'),
          ld_suggestion_item_visit: count_for_verb(params, 'ld_suggestion_item_visit'),
          ld_suggestion_forum_visit: count_for_verb(params, 'ld_suggestion_forum_visit'),
          ld_suggestion_recap_visit: count_for_verb(params, 'ld_suggestion_recap_visit')
        }
      end

      def self.count_for_verb(params, verb)
        start_date = params[:start_date]
        end_date = params[:end_date]

        datasource.exec do |client|
          query = {
            query: {
              bool: {
                must: [
                  match: { verb: verb }
                ] + all_filters(params[:user_id], params[:course_id], nil)
              }
            }
          }
          query[:query][:bool][:filter] = {
            range: {
              timestamp: {
                gte: DateTime.parse(start_date).iso8601,
                lte: DateTime.parse(end_date).iso8601
              }
            }
          } if start_date.present? and end_date.present?

          client.count index: datasource.index, body: query
        end.fetch('count')
      end
    end
  end
end
