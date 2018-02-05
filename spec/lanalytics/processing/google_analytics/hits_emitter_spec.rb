require 'rails_helper'

describe Lanalytics::Processing::GoogleAnalytics::HitsEmitter do

  let(:message) do
    payload = {:v => '1', :tid => 'UA-424242', :qt => Time.new(2018, 01, 01)}
    message = instance_double(Msgr::Message, :payload => payload)
    allow(message).to receive(:ack)
    allow(message).to receive(:nack)
    message
  end

  let(:queue) do
    queue = double('BatchingQueue')
    allow(queue).to receive(:push)
    queue
  end

  describe('in debug mode') do
    before(:each) do
      stub_request(:post, 'https://www.google-analytics.com/debug/collect')
          .to_return(status: 200)
      @emitter = Lanalytics::Processing::GoogleAnalytics::HitsEmitter.send :new, debug: true
      allow(@emitter).to receive(:batching_queue).and_return(queue)
    end

    it 'sends hits to debug API endpoint' do
      @emitter.flush [message]

      assert_requested(:post, 'https://www.google-analytics.com/debug/collect')
      assert_not_requested(:post, 'https://www.google-analytics.com/batch')
    end
  end

  describe('in production mode') do
    before(:each) do
      stub_request(:post, 'https://www.google-analytics.com/batch')
          .to_return(status: 200)
      @emitter = Lanalytics::Processing::GoogleAnalytics::HitsEmitter.send :new, debug: false
      allow(@emitter).to receive(:batching_queue).and_return(queue)
    end

    it 'pushes emitted messages into the batching queue' do
      expect(queue).to receive(:push).with(message)

      @emitter.emit message
    end

    it 'adapts queue time of hit correctly' do
      @emitter.flush [message]

      time_diff = (Time.now - Time.new(2018, 01, 01)).to_i
      assert_requested(:post, 'https://www.google-analytics.com/batch') do |req|
        hit = Rack::Utils.parse_nested_query(req.body.chomp).symbolize_keys
        hit[:qt].to_i.between?(time_diff - 2, time_diff + 2)
      end
    end

    it 'acknowledges messages when successfully sent batch' do
      expect(message).to receive(:ack)
      expect(message).not_to receive(:nack)

      @emitter.flush [message]
    end

    it 'negatively acknowledges messages on errors' do
      stub_request(:post, 'https://www.google-analytics.com/batch')
          .to_raise(Errno::ECONNREFUSED)

      expect(message).to receive(:nack)
      expect(message).not_to receive(:ack)

      @emitter.flush [message]
    end
  end

  def assert_sent_hit(properties)
    assert_requested(:post, 'https://www.google-analytics.com/batch') do |req|
      hits = req.body.lines.map(&:chomp).map{ |hit| Rack::Utils.parse_nested_query(hit).symbolize_keys }
      hits.any { |hit| hit == hit.merge(properties) }
    end
  end

end