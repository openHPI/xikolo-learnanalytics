# frozen_string_literal:true

require 'spec_helper'

RSpec.describe Xikolo::Progress do
  subject(:progress) { described_class.new }

  it 'calculates global progress from multiple counters' do
    progress.update('A', 50, max: 100)
    progress.update('B', 0, max: 100)
    progress.update('B', 50)

    summary = progress.get
    expect(summary.value).to eq 100
    expect(summary.total).to eq 200
    expect(summary.percentage).to eq 50
    expect(summary.to_f).to eq 0.5
  end

  context 'with callback' do
    it 'invokes the callback with summary on update' do
      block = proc {}
      expect(block).to receive(:call) do |summary|
        expect(summary.to_f).to eq 0.5
      end
      expect(block).to receive(:call) do |summary|
        expect(summary.to_f).to eq 0.25
      end

      progress = described_class.new(&block)
      progress.update('A', 50, max: 100)
      progress.update('A', 25)
    end
  end
end
