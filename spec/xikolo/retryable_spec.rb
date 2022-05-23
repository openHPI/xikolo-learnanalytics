# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::Retryable do
  before do
    Stub.request(:course, :get)
      .to_return Stub.json(stats_url: '/stats')
  end

  let(:retryable) { described_class.new(max_retries: max_retries, wait: wait, &promise_block) }
  let(:max_retries) { 3 }
  let(:wait) { 0 }
  let(:promise_block) { proc { Restify.new(:course).get.value!.rel(:stats).get } }

  describe '#retry!' do
    subject(:the_retry) { retryable.retry! }

    context 'retry possible' do
      before do
        Stub.request(
          :course, :get, '/stats'
        ).to_return(
          status: 502,
        ).to_return(
          Stub.json(kpi: 3000),
        )
      end

      it 'executed the retry' do
        expect(the_retry.value!['kpi']).to eq 3000
      end
    end

    context 'retries exhausted' do
      before do
        Stub.request(
          :course, :get, '/stats'
        ).to_return(
          status: 502,
        )

        retryable.retry!
      end

      let(:max_retries) { 1 }

      it 'raises error' do
        expect { the_retry }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#retryable?' do
    subject(:retryable?) { retryable.retryable? }

    before do
      Stub.request(
        :course, :get, '/stats'
      ).to_return Stub.json(
        kpi: 3000,
      )
    end

    let(:max_retries) { 1 }

    it 'returns true' do
      expect(retryable?).to be true
    end

    context 'retries exhausted' do
      before do
        retryable.retry!
      end

      it 'returns false' do
        expect(retryable?).to be false
      end
    end
  end

  describe '#value!' do
    subject(:value) { retryable.value! }

    before do
      Stub.request(
        :course, :get, '/stats'
      ).to_return Stub.json(
        kpi: 3000,
      )
    end

    it 'returns the promise\'s value' do
      expect(value['kpi']).to eq(3000)
    end
  end

  describe '#success?' do
    subject(:success) { retryable.success? }

    context 'successful response' do
      before do
        Stub.request(
          :course, :get, '/stats'
        ).to_return Stub.json(
          kpi: 3000,
        )
      end

      it 'returns true' do
        retryable.value!
        expect(success).to be true
      end
    end

    context 'unsuccessful response' do
      before do
        Stub.request(
          :course, :get, '/stats'
        ).to_return(
          status: 500,
        )
      end

      it 'returns false' do
        expect { retryable.value! }.to raise_error(Restify::ServerError)
        expect(success).to be false
      end
    end
  end
end
