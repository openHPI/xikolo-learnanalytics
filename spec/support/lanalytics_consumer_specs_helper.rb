module LanalyticsConsumerSpecsHelper

  def prepare_rabbitmq_stubs(payload, routing_key)
    allow(@consumer).to receive(:payload).and_return(payload)
    allow(@consumer).to receive(:message).and_return(instance_double('Message', :payload => payload))
    allow(@consumer.message).to receive(:delivery_info).and_return({routing_key: routing_key}) 
  end

end