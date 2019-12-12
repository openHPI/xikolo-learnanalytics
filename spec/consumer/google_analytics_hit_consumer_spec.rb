require 'rails_helper'

describe GoogleAnalyticsHitConsumer do
  include LanalyticsConsumerSpecsHelper

  before(:each) do
    allow(consumer).to receive(:emitter).and_return(emitter)

    stub_request(:head, 'http://localhost:9200/')
        .to_return(status: 200)
  end
  let(:emitter) { instance_double(Lanalytics::Processing::GoogleAnalytics::HitsEmitter) }
  let(:consumer) { described_class.new }

  describe "(:emit)" do
    before(:each) do
      prepare_rabbitmq_stubs(consumer, {dummy_property: 'dummy_value'}, 'xikolo.lanalytics.test_hit.emit')
    end

    it 'should pass the message to the emitter' do
      expect(emitter).to receive(:emit).with(have_attributes(payload: {dummy_property: 'dummy_value'}))
      consumer.emit
    end
  end

end
