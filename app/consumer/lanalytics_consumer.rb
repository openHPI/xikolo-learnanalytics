class LanalyticsConsumer < Msgr::Consumer

  def create
    process_message_with(Lanalytics::Processing::ProcessingAction::CREATE)
  end

  def update
    process_message_with(Lanalytics::Processing::ProcessingAction::UPDATE)
  end

  def destroy
    process_message_with(Lanalytics::Processing::ProcessingAction::DESTROY)
  end

  def handle_user_event
    process_message_with(Lanalytics::Processing::ProcessingAction::CREATE)
  end

  def process_message_with(processing_action)
    pipeline_name = message.delivery_info[:routing_key] # e.g. "xikolo.course.enrollment.update"

    pipeline_manager.schema_pipelines_with(processing_action, pipeline_name).each do | schema, schema_pipeline |
      schema_pipeline.process(payload, processing_opts(message))
    end
  end

  def pipeline_manager
    return Lanalytics::Processing::PipelineManager.instance
  end

  def processing_opts(message)
    return {
      amqp_message: message
    }
  end
end
