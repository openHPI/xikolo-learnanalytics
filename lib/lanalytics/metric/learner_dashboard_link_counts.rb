module Lanalytics
  module Metric
    class LearnerDashboardLinkCounts < ExpApiMetric

      description 'Counts the number of clicks on links (to forum, items, sections) in the learner dashboard.'

      optional_parameter :user_id, :course_id

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
        datasource.exec do |client|
          body = {
            query: {
              bool: {
                must: [
                  match: { verb: verb }
                ] + all_filters(params[:user_id], params[:course_id], nil)
              }
            }
          }

          client.count index: datasource.index, body: body
        end.fetch('count')
      end
    end
  end
end
