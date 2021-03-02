# frozen_string_literal: true

module Lanalytics
  module Metric
    class SectionConversions < ExpEventsPostgresMetric
      description <<~DOC
        Calculate nodes and links to display every users' item visits from
        section to section as a sankey diagram
      DOC

      required_parameter :course_id

      exec do |params|
        course_id = params[:course_id]

        course_service = Restify.new(:course).get.value!

        # get course
        course = course_service.rel(:course).get(id: course_id).value!

        # start and end date are required and course has to be started
        next if course['start_date'].blank? ||
                course['end_date'].blank? ||
                course['start_date'].to_datetime.future?

        # get all sections for course
        sections = []
        Xikolo.paginate(
          course_service.rel(:sections).get(
            course_id: course_id,
            published: true,
            include_alternatives: false,
          ),
        ) do |section|
          sections.append(section)
        end

        # get all items for course
        items = []
        Xikolo.paginate(
          course_service.rel(:items).get(course_id: course_id),
        ) do |item|
          items.append(item)
        end

        # get unique item visit count per user and section
        # example: [ { user_id: '123', section_id: '321', item_count: 3 } ]
        query = <<~SQL
          SELECT e.user_uuid as user_id, e.in_context->>'section_id' as section_id, COUNT(DISTINCT r.uuid) as item_count
          FROM events as e, verbs as v, resources as r
          WHERE e.verb_id = v.id
            AND e.resource_id = r.id
            AND e.in_context->>'course_id' = '#{course_id}'
            AND v.verb = 'visited_item'
            AND (e.in_context->>'section_id') IS NOT NULL
            AND e.created_at >= '#{Date.parse(course['start_date']).iso8601}'::date
            AND e.created_at <= '#{Date.parse(course['end_date']).iso8601}'::date
          GROUP BY user_id, section_id
        SQL
        item_visit_counts = perform_query(query)

        # prepare required section data
        section_count = sections.size
        section_data = sections.map do |section|
          [
            section['id'],
            {
              position: section['position'],
              item_count: items.select do |item|
                item['section_id'] == section['id']
              end.size,
            },
          ]
        end.to_h

        # calculate for all users (hash key) the visited percentage for all
        # sections (hash value as array, where index is section position)
        # example: { 'user_id_123' => [1, 0.2, 0.1, 0, 0] }
        item_visit_percentage = {}
        item_visit_counts.each do |result|
          unless item_visit_percentage.key? result['user_id']
            item_visit_percentage[result['user_id']] =
              Array.new(section_count, 0)
          end
          section = section_data[result['section_id']]

          next if section.blank?

          # rubocop:disable Style/FloatDivision
          item_visit_percentage[result['user_id']][section[:position] - 1] =
            result['item_count'].to_f / section[:item_count].to_f
          # rubocop:enable all
        end

        # inverse sorted buckets
        buckets = [1, 0.8, 0.6, 0.4, 0.2, 0]
        bucket_for = proc do |value|
          next 0 if value == buckets.first

          buckets.select {|threshold| threshold > value }.size
        end

        # calculate links for all nodes, where source and target (hash key) are
        # mapped to a number of user (hash value)
        # example: { [1, 3] => 6 }
        # Nodes are defined based on buckets, which represent a certain visited
        # percentage threshold. Source and target point to nodes, whereby a node
        # is referenced by its implicit order. The implicit order is defined by
        # the bucket index and section index,
        source_target_values = {}

        # provide some empty links to show nodes with no source and target for a
        # better visualization
        (section_count - 1).times do |s_i|
          (buckets.size + 1).times do |b_i|
            key = [
              s_i * (buckets.size + 1) + b_i,         # source node
              (s_i + 1) * (buckets.size + 1) + b_i,   # target node
            ]
            source_target_values[key] = 0
          end
        end

        item_visit_percentage.values.each do |user_values|
          user_values.zip(user_values.drop(1)).each_with_index do |(a, b), i|
            # the index of b is the index of a + 1 (the next section)
            next if a.nil? || b.nil?

            key = [
              i * (buckets.size + 1) + bucket_for.call(a),         # source node
              (i + 1) * (buckets.size + 1) + bucket_for.call(b),   # target node
            ]

            source_target_values[key] = 0 unless source_target_values.key? key

            source_target_values[key] += 1
          end
        end

        # build final nodes and links data structure, which is optimized
        # for the visualization
        nodes = sections.each_with_index.flat_map do |_, s_i|
          (0...(buckets.size + 1)).map do |b_i|
            if b_i == 0
              name = format('%.2f', buckets[b_i]).to_s
            elsif b_i == buckets.size
              name = format('%.2f', buckets[b_i - 1]).to_s
            elsif b_i == buckets.size - 1
              from = format('%.2f', buckets[b_i - 1] - 0.01)
              to = format('%.2f', buckets[b_i] + 0.01)
              name = "#{from}-#{to}"
            else
              from = format('%.2f', buckets[b_i - 1] - 0.01)
              to = format('%.2f', buckets[b_i])
              name = "#{from}-#{to}"
            end
            {
              name: name,
              id: "section-#{s_i}-bucket-#{b_i}",
            }
          end
        end

        links = source_target_values.map do |(source, target), value|
          {
            source: source,
            target: target,
            value: value,
          }
        end

        {
          nodes: nodes,
          links: links,
        }
      end
    end
  end
end
