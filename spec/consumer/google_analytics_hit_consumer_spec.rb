require 'rails_helper'

describe GoogleAnalyticsHitConsumer do
  include LanalyticsConsumerSpecsHelper

  before(:each) do
    @emitter = double('Emitter')
    @consumer = GoogleAnalyticsHitConsumer.new
    allow(@consumer).to receive(:emitter).and_return(@emitter)

    stub_request(:head, 'http://localhost:9200/')
        .to_return(status: 200)
  end

  describe "(:emit)" do
    before(:each) do
      @dummy_event_data = {dummy_property: 'dummy_value'}
      prepare_rabbitmq_stubs(@dummy_event_data, 'xikolo.lanalytics.test_hit.emit')
    end

    it 'should pass the message to the emitter' do
      expect(@emitter).to receive(:emit).with(have_attributes(:payload => @dummy_event_data))
      @consumer.emit
    end
  end

end
