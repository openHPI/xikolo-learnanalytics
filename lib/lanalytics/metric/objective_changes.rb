module Lanalytics
  module Metric
    class ObjectiveChanges < ExpApiMetric

      description 'Number of changes between objectives by pairs of objectives.'

      optional_parameter :course_id, :user_id

      exec do |params|
        course_id = params[:course_id]
        user_id = params[:user_id]

        result = datasource.exec do |client|
          query_must = [
            { match: { 'verb' => 'selected_objective' } },
            { exists: { field: 'in_context.old_objective' } }
          ]

          if user_id.present?
            query_must << { match: { 'user.resource_uuid' => user_id } }
          end

          if course_id.present?
            query_must << { match: { 'in_context.context_id' => course_id } }
          end

          body = {
            size: 0,
            query: {
              bool: {
                must: query_must
              }
            },
            aggs: {
              old_objective: {
                terms: { field: 'in_context.old_objective' },
                aggs: {
                  new_objective: {
                    terms: { field: 'in_context.new_objective' }
                  }
                }
              },
            }
          }

          client.search index: datasource.index, body: body
        end

        {
          result: result.dig('aggregations', 'old_objective', 'buckets')&.each_with_object([]) do |old, res|
            old.dig('new_objective', 'buckets')&.each do |new|
              res << { old: old['key'], new: new['key'], count: new['doc_count'] }
            end
            res
          end
        }
      end
    end
  end
end
