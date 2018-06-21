module QcRules
  class ExitItem
    def initialize(rule)
      @rule = rule
    end

    def run(course)
      if course['end_date'] && course['end_date'].to_date.past?
        @rule.alerts_for(course_id: course['id']).close!
        return
      end

      return unless %w[active archive].include?(course['status']) && metric_available?

      all_items = get_items course
      metric_results = calculate_metric(course)[:items].map{ |item| [item[:item_id], item] }.to_h
      all_items.select{ |item| !last_in_section?(all_items, item) }.each do |item|
        page_views = metric_results.dig item.id, :total_pageviews
        exit_rate = metric_results.dig item.id, :relative_exits
        next if page_views.nil? || exit_rate.nil?

        if page_views > config['page_view_threshold'] && exit_rate > config['low_threshold']
          @rule.alerts_for(course_id: course.id)
            .with_data(resource_id: item.id)
            .open!(
              severity: severity(exit_rate),
              annotation: "#{exit_rate.round(2)}% of item visits are the last action within a session."
            )
        else
          @rule.alerts_for(course_id: course.id)
            .with_data(resource_id: item.id)
            .close!
        end
      end

    end

    private

    def config
      Xikolo.config.qc_alert['exit_item']
    end

    def metric_available?
      Lanalytics::Metric::ExitItems.available?
    end

    def calculate_metric(course)
      Lanalytics::Metric::ExitItems.query(course_id: course['id'])
    end

    def last_in_section?(all_items, item)
      all_items.none?{ |other_item| other_item.section_id == item.section_id && other_item.position > item.position }
    end

    def get_items(course)
      items = []
      Xikolo.paginate(
        Xikolo.api(:course).value!.rel(:items).get(
          course_id: course.id,
          published: true
        )
      ) do |item|
        items << item
      end

      items
    end

    def severity(exit_rate)
      if exit_rate > config['high_threshold']
        'high'
      elsif exit_rate > config['medium_threshold']
        'medium'
      else
        'low'
      end
    end

  end
end