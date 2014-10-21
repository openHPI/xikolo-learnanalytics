class LanalyticsResourceConsumer < Msgr::Consumer

  def create
    puts "create Nachricht angekommen #{payload.inspect}"
    Lanalytics::Processing.instance.process_data_for(message.delivery_info[:routing_key], payload, processing_opts(message))
  end

  def update
    puts "update Nachricht angekommen #{payload.inspect}"
    Lanalytics::Processing.instance.process_data_for(message.delivery_info[:routing_key], payload, processing_opts(message))
  end

  def destroy
    puts "Destroy Nachricht angekommen #{payload.inspect}"
    Lanalytics::Processing.instance.process_data_for(message.delivery_info[:routing_key], payload, processing_opts(message))
  end

  def processing_opts(message)
    return {
      import_action: "#{/xikolo\..*\..*\.(?<action>create|update|destroy)/.match(message.delivery_info[:routing_key])[:action]}".to_sym.upcase,
      rabbit_message: message
    }
  end
end