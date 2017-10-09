class QcAlertCollection
  def initialize(alerts)
    @alerts = alerts
    @data_conditions = {}
  end

  def with_data(**conditions)
    @data_conditions = conditions
    self
  end

  def close!
    matching_alerts.each do |alert|
      alert.close!
    end
  end

  def open!(**attrs)
    matching_alerts.first_or_initialize.tap { |alert|
      alert.assign_attributes attrs.merge(status: 'open')

      # Make sure nested conditions are merged back into the alert data hash.
      # This is necessary in case attrs contains a value for this hash as well.
      alert.qc_alert_data = (alert.qc_alert_data || {}).merge(@data_conditions)
    }.save!
  end

  private

  def matching_alerts
    @matching_alerts ||= @alerts.tap { |query|
      @data_conditions.each do |key, value|
        query.where!("(qc_alert_data->>'#{key}') = ?", value)
      end
    }
  end
end
