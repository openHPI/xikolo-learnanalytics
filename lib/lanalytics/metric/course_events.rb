module Lanalytics
  module Metric
    class CourseEvents < ExpApiMetric

      description 'Returns raw course events (paginated).'

      required_parameter :course_id

      optional_parameter :start_date, :end_date, :page, :per_page, :scroll_id, :verb

      exec do |params|
        course_id = params[:course_id]
        start_date = params[:start_date]
        end_date = params[:end_date]
        page = params[:page] || 1
        per_page = params[:per_page] || 1000
        scroll_id = params[:scroll_id]

        start_date = start_date.present? ? DateTime.parse(start_date) : (DateTime.now - 1.day)
        end_date = end_date.present? ? DateTime.parse(end_date) : (DateTime.now)

        verb = params[:verb]

        if scroll_id.nil?
          body = {
            query: {
              bool: {
                minimum_should_match: 1,
                should: [
                  { match: { 'in_context.course_id' => course_id } },
                  { match: { 'resource.resource_uuid' => course_id } }
                ],
                filter: {
                  range: {
                    timestamp: {
                      gte: start_date.iso8601,
                      lte: end_date.iso8601
                    }
                  }
                }
              }
            },
            sort: ['_doc'],
            size: per_page
          }

          if verb.present?
            body[:query][:bool][:must] = {
              wildcard: {
                verb: verb
              }
            }
          end

          result = datasource.exec do |client|
            client.search index: datasource.index,
                          scroll: '5m',
                          body: body
          end
        else
          result = datasource.exec do |client|
            client.scroll scroll: '5m', scroll_id: scroll_id, body: { scroll_id: scroll_id }
          end
        end

        processed_result = []

        result['hits']['hits'].each do |item|
          ev = {
              user_id: item['_source']['user']['resource_uuid'],
              verb: item['_source']['verb'],
              resource_id: item['_source']['resource']['resource_uuid'],
              timestamp:  item['_source']['timestamp'],
              context: item['_source']['in_context'].to_json
          }
          processed_result << ev
        end

        current_last = result['hits']['hits'].count + (page.to_i - 1) * per_page

        {
          data: processed_result,
          next: current_last < result['hits']['total'],
          scroll_id: result['_scroll_id'],
          total_pages: (result['hits']['total'] / per_page.to_f).ceil
        }
      end

    end
  end
end
