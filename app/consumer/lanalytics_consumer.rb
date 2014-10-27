class LanalyticsConsumer < Msgr::Consumer

  def create
    Lanalytics::Processing::AmqpProcessingManager.instance.process_data_for(message.delivery_info[:routing_key], payload, processing_opts(message))
  end

  def update
    Lanalytics::Processing::AmqpProcessingManager.instance.process_data_for(message.delivery_info[:routing_key], payload, processing_opts(message))
  end

  def destroy
    Lanalytics::Processing::AmqpProcessingManager.instance.process_data_for(message.delivery_info[:routing_key], payload, processing_opts(message))
  end

  def handle_user_event
    Lanalytics::Processing::AmqpProcessingManager.instance.process_data_for(message.delivery_info[:routing_key], payload, processing_opts(message))
  end

  def processing_opts(message)
    return {
      amqp_message: message
    }
  end
end