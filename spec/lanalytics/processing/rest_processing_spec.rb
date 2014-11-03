require 'rails_helper'

describe Lanalytics::Processing::RestProcessing do

  it 'processes url on one page' do
    data_1 = {'id' => '1', 'property' => 'A'}
    stub_request(:get, 'http://localhost:3000/data.json').to_return(status: 200,
      headers: { 'link' => '<http://localhost:3000/data.json?page=1>; rel="first", <http://localhost:3000/data.json?page=1>; rel="last"' },
      body: [
        data_1,
        {'id' => '2', 'property' => 'B'},
        {'id' => '3', 'property' => 'C'},
        {'id' => '4', 'property' => 'D'},
        {'id' => '5', 'property' => 'E'}
      ].to_json)

    processing_step = Lanalytics::Processing::ProcessingStep.new
    expect(processing_step).to receive(:process).with(data_1, anything(), anything())
    expect(processing_step).to receive(:process).with(kind_of(Hash), anything(), anything()).exactly(4).times
    Lanalytics::Processing::RestProcessing.process('http://localhost:3000/data.json', [processing_step])
  end

  it 'processes url on two pages' do
    data_1 = {'id' => '1', 'property' => 'A'}
    stub_request(:get, 'http://localhost:3000/data.json').to_return(status: 200,
      headers: { 'link' => '<http://localhost:3000/data.json?page=1>; rel="first", <http://localhost:3000/data.json?page=2>; rel="next", <http://localhost:3000/data.json?page=2>; rel="last"' },
      body: [ data_1, {'id' => '2', 'property' => 'B'}].to_json)

    data_3 = {'id' => '3', 'property' => 'C'}
    stub_request(:get, 'http://localhost:3000/data.json?page=2').to_return(status: 200,
      headers: { 'link' => '<http://localhost:3000/data.json?page=1>; rel="first", <http://localhost:3000/data.json?page=1>; rel="prev", <http://localhost:3000/data.json?page=2>; rel="last"' },
      body: [ data_3, {'id' => '4', 'property' => 'D'} ].to_json)

    processing_step = Lanalytics::Processing::ProcessingStep.new
    # expect(processing_step).to receive(:process).exactly(5).times
    expect(processing_step).to receive(:process).with(data_1, anything(), anything())
    expect(processing_step).to receive(:process).with(kind_of(Hash), anything(), anything())
    expect(processing_step).to receive(:process).with(data_3, anything(), anything())
    expect(processing_step).to receive(:process).with(kind_of(Hash), anything(), anything())
    expect(processing_step).to_not receive(:process)
    Lanalytics::Processing::RestProcessing.process('http://localhost:3000/data.json', [processing_step])
  end

  it "processes url with no link header" do

    data_1 = {'id' => '1', 'property' => 'A'}
    stub_request(:get, 'http://localhost:3000/data.json').to_return(status: 200,
      body: [
        data_1,
        {'id' => '2', 'property' => 'B'},
        {'id' => '3', 'property' => 'C'},
        {'id' => '4', 'property' => 'D'},
        {'id' => '5', 'property' => 'E'}
      ].to_json)

    processing_step = Lanalytics::Processing::ProcessingStep.new
    expect(processing_step).to receive(:process).with(data_1, anything(), anything())
    expect(processing_step).to receive(:process).with(kind_of(Hash), anything(), anything()).exactly(4).times
    Lanalytics::Processing::RestProcessing.process('http://localhost:3000/data.json', [processing_step])
  end

end