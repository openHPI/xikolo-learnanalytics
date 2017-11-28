class GoogleAnalyticsHitConsumer < Msgr::Consumer
  self.auto_ack = false

  def emit
    emitter.emit message
  end

  def emitter
    Lanalytics::Processing::GoogleAnalytics::HitsEmitter.instance
  end
end