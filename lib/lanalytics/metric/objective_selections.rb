module Lanalytics
  module Metric
    class ObjectiveSelections < ExpApiMetric

      description 'Learning objective measures including the number of users with objective, selections by objective, average number of objectives, and distribution of selected objectives.'

      optional_parameter :course_id, :user_id

      exec do |params|
        course_id = params[:course_id]
        user_id = params[:user_id]

        result = datasource.exec do |client|
          query_must = [ { match: { 'verb' => 'selected_objective' } } ]

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
              distinct_user_count: {
                cardinality: {
                  field: 'user.resource_uuid'
                }
              },
              by_objective: {
                terms: {
                  field: 'in_context.new_objective',
                  order: {_count: 'desc'}
                },
                aggs: {
                  initial_objectives: {
                    missing: { field: 'in_context.old_objective' }
                  },
                }
              },
              by_user: {
                terms: {
                  field: 'user.resource_uuid',
                  order: {_count: 'desc'},
                  size: 30000
                },
                aggs: {
                  current_objective: {
                    top_hits: {
                      sort: { timestamp: { order: 'desc' } },
                      size: 1,
                      _source: 'in_context.new_objective'
                    }
                  }
                }
              },
              initial_objectives: {
                missing: { field: 'in_context.old_objective' },
                aggs: {
                  by_modal_context: {
                    terms: {
                      field: 'in_context.objectives_modal_context'
                    }
                  }
                }
              }
            }
          }

          client.search index: datasource.index, body: body
        end

        active_objectives = result.dig('aggregations', 'by_user', 'buckets')&.map do |b|
          b.dig('current_objective', 'hits', 'hits', 0, '_source', 'in_context', 'new_objective')
        end.each_with_object(Hash.new(0)) { |e, h| h[e] += 1 }
        total_selections_by_objective = result.dig('aggregations', 'by_objective', 'buckets')&.each_with_object({}) do |e, h|
          h[e['key']] = e['doc_count']
        end
        objectives_per_user = result.dig('aggregations', 'by_user', 'buckets')&.map  { |b| b['doc_count'] }
        initial_objectives = result.dig('aggregations', 'by_objective', 'buckets')&.each_with_object({}) do |e, h|
          h[e['key']] = e.dig('initial_objectives', 'doc_count')
        end
        initial_selections_by_context = result.dig('aggregations', 'initial_objectives', 'by_modal_context', 'buckets')&.each_with_object({}) do |e, h|
          h[e['key']] = e['doc_count']
        end

        {
          # Count users with selected learning objectives
          total_active_objectives: result.dig('aggregations', 'distinct_user_count', 'value'),
          # Count currently selected (active) objectives (by objective_id)
          active_objectives: active_objectives,
          # Count total selections
          total_selections: result.dig('hits', 'total'),
          # Count total selections (by objective_id)
          total_selections_by_objective: total_selections_by_objective,
          # Average number of objectives per user
          avg_objectives_per_user: objectives_per_user.present? ? (objectives_per_user.reduce(:+) / objectives_per_user.size.to_f) : nil,
          # Count how often an objective was selected as first objective
          initial_objectives: initial_objectives,
          # Count the number of initial selections per modal context in which they were selected (infobox, popup, progress)
          initial_selections_by_context: initial_selections_by_context
        }
      end
    end
  end
end
