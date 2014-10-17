class LanalyticsResourceConsumer < Msgr::Consumer

  def create
    puts "Nachricht angekommen #{payload.inspect}"
    # Lanalytics::Processing.new(
    #   Lanalytics.Processor::Neo4jProcessor.new(),

    #   Lanalytics.Processor::Neo4jProcessor.new()
    #   Lanalytics.Processor::Neo4jProcessor.new()
    #   )
  end

  def update

    puts "Nachricht angekommen #{payload.inspect}"
    Lanalytics::Processing.instance.process_data_for(message.delivery_info[:routing_key], payload, message)


    #Lanalytics::Processing.new(
    #  Lanalytics.Processor::Neo4jProcessor.new(),
    #
    #  Lanalytics.Processor::Neo4jProcessor.new()
    #  Lanalytics.Processor::Neo4jProcessor.new()
    #  )
  end

  def destroy
    puts "Nachricht angekommen #{payload.inspect}"
  end
end