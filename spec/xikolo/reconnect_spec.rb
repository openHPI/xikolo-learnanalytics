# frozen_string_literal: true

require 'spec_helper'

class ConnectionThatErrors
  def initialize(times:, &error_block)
    @error_block = error_block
    @query_count = 0
    @expected_error_count = times
  end

  def execute_query
    @query_count += 1

    @error_block.call if @query_count <= @expected_error_count
  end

  attr_reader :query_count
end

describe Xikolo::Reconnect do
  context 'without error' do
    it 'executes the given block once' do
      expect do |b|
        described_class.on_stale_connection(&b)
      end.to yield_with_no_args
    end
  end

  context 'when ActiveRecord catches a PG::ConnectionBad error' do
    let(:connection) do
      ConnectionThatErrors.new(times: 1) do
        raise PG::ConnectionBad
      rescue PG::ConnectionBad
        raise ActiveRecord::StatementInvalid
      end
    end

    it 'retries the block' do
      described_class.on_stale_connection do
        connection.execute_query
      end

      expect(connection.query_count).to eq 2
    end

    it 'tries to reconnect to the database' do
      expect(ActiveRecord::Base.connection).to receive(:reconnect!).and_call_original

      described_class.on_stale_connection do
        connection.execute_query
      end
    end
  end

  context 'when the retry also errors' do
    let(:connection) do
      ConnectionThatErrors.new(times: 2) do
        raise PG::ConnectionBad
      rescue PG::ConnectionBad
        raise ActiveRecord::StatementInvalid
      end
    end

    it 'retries the block, but only once, and then raises' do
      expect do
        described_class.on_stale_connection { connection.execute_query }
      end.to raise_error(ActiveRecord::StatementInvalid)

      expect(connection.query_count).to eq 2
    end
  end

  context 'when ActiveRecord catches a different error' do
    let(:connection) do
      ConnectionThatErrors.new(times: 1) do
        raise 'Invalid SQL'
      rescue
        raise ActiveRecord::StatementInvalid
      end
    end

    it 'bubbles up the exception' do
      expect do
        described_class.on_stale_connection { connection.execute_query }
      end.to raise_error(ActiveRecord::StatementInvalid)

      expect(connection.query_count).to eq 1
    end
  end
end
