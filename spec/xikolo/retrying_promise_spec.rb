# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::RetryingPromise do
  before do
    Stub.request(:course, :get)
      .to_return Stub.json({
        stats1_url: '/stats1',
        stats2_url: '/stats2',
        stats3_url: '/stats3',
      })
    Stub.request(
      :course, :get, '/stats1'
    ).to_return Stub.json({
      kpi: 1000,
    })
    Stub.request(
      :course, :get, '/stats2'
    ).to_return Stub.json({
      kpi: 2000,
    })
  end

  let(:retrying_promise) { described_class.new(dependencies, &task) }
  let(:dependencies) do
    [
      Xikolo::Retryable.new(max_retries: 3, wait: 0) { Restify.new(:course).get.value!.rel(:stats1).get },
      Xikolo::Retryable.new(max_retries: 3, wait: 0) { Restify.new(:course).get.value!.rel(:stats2).get },
      Xikolo::Retryable.new(max_retries: 3, wait: 0) { Restify.new(:course).get.value!.rel(:stats3).get },
    ]
  end
  let(:task) do
    proc do |retryable1, retryable2, retryable3|
      "#{retryable1['kpi']}, #{retryable2['kpi']}, #{retryable3['kpi']}"
    end
  end

  describe '#value!' do
    subject(:value) { retrying_promise.value! }

    context 'with all promises succeeding' do
      before do
        Stub.request(
          :course, :get, '/stats3'
        ).to_return Stub.json({
          kpi: 3000,
        })
      end

      it 'returns all promise results' do
        expect(value).to eq '1000, 2000, 3000'
      end
    end

    context 'with a three times failing promise and successful retry afterward' do
      before do
        Stub.request(
          :course, :get, '/stats3'
        ).to_return(
          status: 502,
        ).to_return(
          status: 503,
        ).to_return(
          status: 504,
        ).to_return Stub.json({
          kpi: 3000,
        })
      end

      it 'returns all promise results' do
        expect(value).to eq '1000, 2000, 3000'
      end
    end

    context 'with a too often failing promise' do
      before do
        Stub.request(
          :course, :get, '/stats3'
        ).to_return(
          status: 502,
        )
      end

      it 'raises error' do
        expect { value }.to raise_error(RuntimeError)
      end
    end

    context 'with a non-retryable status code' do
      before do
        Stub.request(
          :course, :get, '/stats3'
        ).to_return(
          status: 500,
        )
      end

      it 'raises error' do
        expect { value }.to raise_error(Restify::ServerError)
      end
    end
  end
end
