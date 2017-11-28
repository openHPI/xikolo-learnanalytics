require 'rails_helper'

describe Lanalytics::Processing::BatchingQueue do

  class Receiver
  end

  let(:item) do
    double('item')
  end
  let(:receiver) do
    receiver = Receiver.new
    allow(receiver).to receive(:flush)
    receiver
  end

  before(:each) do
    @batching_queue = Lanalytics::Processing::BatchingQueue.new max_batch_size: 3, max_queue_time: 1.seconds
    @batching_queue.on_flush { |batch| receiver.flush batch }
  end

  it 'queues item if max batch size is not reached' do
    expect(receiver).not_to receive(:flush)
    @batching_queue.push item
  end

  it 'sends items as batch when max batch size is reached' do
    expect(receiver).to receive(:flush) do |items|
      expect(items.size).to eq(3)
    end
    3.times { @batching_queue.push item }
  end

  it 'does not exceed max batch size when pushing items' do
    expect(receiver).to receive(:flush) do |items|
      expect(items.size).to eq(3)
    end
    4.times { @batching_queue.push item }
  end

  it 'flushes single item after max queue time' do
    @batching_queue.push item

    expect(receiver).to receive(:flush)
    sleep 2.seconds
  end

  it 'when receiving multiple items less than batch size, flushes all items only once after max queue time' do
    2.times { @batching_queue.push item }

    expect(receiver).to receive(:flush).once do |items|
      expect(items.size).to eq(2)
    end
    sleep 2.seconds
  end

  it 'does not flush items twice after max queue time if max batch size was reached meanwhile' do
    expect(receiver).to receive(:flush).once do |items|
      expect(items.size).to eq(3)
    end
    3.times { @batching_queue.push item }

    sleep 2.seconds
  end
end