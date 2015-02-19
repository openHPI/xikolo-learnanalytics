module LanalyticsConsumerSpecsHelper

  def prepare_rabbitmq_stubs(payload, routing_key)
    allow(@consumer).to receive(:payload).and_return(payload)
    allow(@consumer).to receive(:message).and_return(double('message'))
    allow(@consumer.message).to receive(:delivery_info).and_return({routing_key: routing_key}) 
  end

end