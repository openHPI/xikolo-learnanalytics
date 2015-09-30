require 'rails_helper'

describe Lanalytics::Processing::RestPipeline do

  describe '(Initialization)' do

    it 'should initialize correctly' do
      expect { rest_pipeline = Lanalytics::Processing::RestPipeline.new('http://localhost:3000/data.json') }.not_to raise_error


      pipeline1 = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::Action::CREATE,
          [Lanalytics::Processing::Extractor::ExtractStep.new],
          [Lanalytics::Processing::Transformer::TransformStep.new],
          [Lanalytics::Processing::Loader::DummyLoadStep.new])
      pipeline2 = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::Action::CREATE,
          [Lanalytics::Processing::Extractor::ExtractStep.new],
          [Lanalytics::Processing::Transformer::TransformStep.new],
          [Lanalytics::Processing::Loader::DummyLoadStep.new])
      expect { rest_pipeline = Lanalytics::Processing::RestPipeline.new('http://localhost:3000/data.json', [pipeline1, pipeline2]) }.to_not raise_error
    end

  end



  it 'processes url on one page' do
    data = [
      {id: '1', property: 'A'},
      {id: '2', property: 'B'},
      {id: '3', property: 'C'},
      {id: '4', property: 'D'},
      {id: '5', property: 'E'}]

    stub_request(:get, 'http://localhost:3000/data.json').to_return(status: 200,
      headers: { 'link' => '<http://localhost:3000/data.json?page=1>; rel="first", <http://localhost:3000/data.json?page=1>; rel="last"' },
      body: [
        data[0],
        data[1],
        data[2],
        data[3],
        data[4]
      ].to_json)

   pipeline = new_test_pipeline
    expect(pipeline).to receive(:process).with(data[0], kind_of(Hash))
    expect(pipeline).to receive(:process).with(data[1], kind_of(Hash))
    expect(pipeline).to receive(:process).with(data[2], kind_of(Hash))
    expect(pipeline).to receive(:process).with(data[3], kind_of(Hash))
    expect(pipeline).to receive(:process).with(data[4], kind_of(Hash))
    Lanalytics::Processing::RestPipeline.process('http://localhost:3000/data.json', [pipeline])
  end


  it 'processes url on two pages' do
    data_1 = {id: '1', property: 'A'}
    stub_request(:get, 'http://localhost:3000/data.json').to_return(status: 200,
      headers: { 'link' => '<http://localhost:3000/data.json?page=1>; rel="first", <http://localhost:3000/data.json?page=2>; rel="next", <http://localhost:3000/data.json?page=2>; rel="last"' },
      body: [ data_1, {id: '2', property: 'B'}].to_json)

    data_3 = {id: '3', property: 'C'}
    stub_request(:get, 'http://localhost:3000/data.json?page=2').to_return(status: 200,
      headers: { 'link' => '<http://localhost:3000/data.json?page=1>; rel="first", <http://localhost:3000/data.json?page=1>; rel="prev", <http://localhost:3000/data.json?page=2>; rel="last"' },
      body: [ data_3, {id: '4', property: 'D'} ].to_json)

    pipeline = new_test_pipeline
    expect(pipeline).to receive(:process).with(data_1, kind_of(Hash))
    expect(pipeline).to receive(:process).with(anything(), kind_of(Hash))
    expect(pipeline).to receive(:process).with(data_3, kind_of(Hash))
    expect(pipeline).to receive(:process).with(anything(),kind_of(Hash))
    expect(pipeline).to_not receive(:process)
    Lanalytics::Processing::RestPipeline.process('http://localhost:3000/data.json', [pipeline])
  end


  it "processes url with no link header" do

    data_1 = {id: '1', property: 'A'}
    stub_request(:get, 'http://localhost:3000/data.json').to_return(status: 200,
      body: [
        data_1,
        {id: '2', property: 'B'},
        {id: '3', property: 'C'},
        {id: '4', property: 'D'},
        {id: '5', property: 'E'}
      ].to_json)

    pipeline = new_test_pipeline
    expect(pipeline).to receive(:process).with(data_1, kind_of(Hash))
    expect(pipeline).to receive(:process).with(kind_of(Hash), kind_of(Hash)).exactly(4).times
    Lanalytics::Processing::RestPipeline.process('http://localhost:3000/data.json', [pipeline])
  end


  def new_test_pipeline
    return Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::Action::CREATE,
      [Lanalytics::Processing::Extractor::ExtractStep.new],
      [Lanalytics::Processing::Transformer::TransformStep.new],
      [Lanalytics::Processing::Loader::DummyLoadStep.new])
  end

end
