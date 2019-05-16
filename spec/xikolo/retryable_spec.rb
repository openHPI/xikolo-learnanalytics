require 'spec_helper'

describe Xikolo::Retryable do
  before do
    Stub.service(
      :course,
      stats_url: '/stats',
    )
  end

  let(:retryable) { described_class.new(max_retries: max_retries, wait: wait, &promise_block) }
  let(:max_retries) { 3 }
  let(:wait) { 0 }
  let(:promise_block) { Proc.new { Xikolo.api(:course).value!.rel(:stats).get } }

  describe '#retry!' do
    subject { retryable.retry! }

    context 'retry possible' do
      before do
        Stub.request(
          :course, :get, '/stats'
        ).to_return(
          status: 502
        ).to_return Stub.json(
          kpi: 3000
        )
      end

      it 'executed the retry' do
        expect(subject.value!['kpi']).to eq 3000
      end
    end

    context 'retries exhausted' do
      before do
        Stub.request(
          :course, :get, '/stats'
        ).to_return(
          status: 502
        )

        retryable.retry!
      end

      let(:max_retries) { 1 }

      it 'should raise error' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#retryable?' do
    before do
      Stub.request(
        :course, :get, '/stats'
      ).to_return Stub.json(
        kpi: 3000
      )
    end

    let(:max_retries) { 1 }

    subject { retryable.retryable? }

    it 'should return true' do
      expect(subject).to eq(true)
    end

    context 'retries exhausted' do
      before do
        retryable.retry!
      end

      it 'should return false' do
        expect(subject).to eq(false)
      end
    end
  end

  describe '#value!' do
    before do
      Stub.request(
        :course, :get, '/stats'
      ).to_return Stub.json(
        kpi: 3000
      )
    end

    subject { retryable.value! }

    it 'returns the promise\'s value' do
      expect(subject['kpi']).to eq(3000)
    end
  end

  describe '#success?' do
    subject { retryable.success? }

    context 'successful response' do
      before do
        Stub.request(
          :course, :get, '/stats'
        ).to_return Stub.json(
          kpi: 3000
        )
      end

      it 'should return true' do
        retryable.value!
        expect(subject).to eq(true)
      end
    end

    context 'unsuccessful response' do
      before do
        Stub.request(
          :course, :get, '/stats'
        ).to_return(
          status: 500
        )
      end

      it 'should return false' do
        expect { retryable.value! }.to raise_error(Restify::ServerError)
        expect(subject).to eq(false)
      end
    end
  end
end
