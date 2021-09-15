# frozen_string_literal: true

class LanalyticsConsumer < Msgr::Consumer
  def create
    process_message_with(Lanalytics::Processing::Action::CREATE)
  end

  def update
    process_message_with(Lanalytics::Processing::Action::UPDATE)
  end

  def destroy
    process_message_with(Lanalytics::Processing::Action::DESTROY)
  end

  def handle_user_event
    process_message_with(Lanalytics::Processing::Action::CREATE)
  end

  def process_message_with(processing_action)
    pipeline_name = message.delivery_info[:routing_key] # e.g. "xikolo.course.enrollment.update"

    pipelines = pipeline_manager.schema_pipelines_with(processing_action, pipeline_name)

    # Only accept messages if data sources are running
    unless pipelines.all? {|_schema, schema_pipeline| schema_pipeline.loaders_available? }
      message.nack
      return
    end

    pipelines.each do |_schema, schema_pipeline|
      schema_pipeline.process(payload, processing_opts(message))
    end
  end

  def pipeline_manager
    Lanalytics::Processing::PipelineManager.instance
  end

  def processing_opts(message)
    {
      amqp_message: message,
    }
  end
end
