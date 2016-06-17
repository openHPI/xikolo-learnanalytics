require 'rails_helper'

describe Lanalytics::Processing::Transformer::ContextData do

  let(:original_event) do
    FactoryGirl.attributes_for(:amqp_exp_stmt).with_indifferent_access
  end

  before(:each) do
    @processing_unit = Lanalytics::Processing::Unit.new(:exp_event, original_event)
    @processing_units = [@processing_unit]
    @load_commands = []
    @pipeline_ctx = OpenStruct.new processing_action: :CREATE

    @context_data_transformer = Lanalytics::Processing::Transformer::ContextData.new
  end

  it 'should do nothing if there is no user user-agent' do
    @context_data_transformer.transform(
        original_event,
        @processing_units,
        @load_commands,
        @pipeline_ctx
    )

    expect(@processing_units).to match_array([@processing_unit])
  end

  describe 'with a mobile user-agent' do
    let(:original_event) do
      FactoryGirl.attributes_for(
          :amqp_exp_stmt,
          in_context: {
              user_agent: 'Mozilla/5.0 (iPad; CPU OS 9_0 like Mac OS X) AppleWebKit/601.1.39 (KHTML, like Gecko) Version/9.0 Mobile/13A4305g Safari/601.1'
          }
      ).with_indifferent_access
    end

    it 'should add context data' do
      @context_data_transformer.transform(
          original_event,
          @processing_units,
          @load_commands,
          @pipeline_ctx
      )

      expect(@processing_units.length).to eq(1)
      in_context = @processing_units[0][:in_context]
      expect(in_context).to include(:platform => "iOS (iPad)")
      expect(in_context).to include(:platform_version => "9")
      expect(in_context).to include(:runtime => "Safari")
      expect(in_context).to include(:runtime_version => "9")
      expect(in_context).to include(:device => "iPad")
    end
  end

  describe 'with a desktop user-agent' do
    let(:original_event) do
      FactoryGirl.attributes_for(
          :amqp_exp_stmt,
          in_context: {
              user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.86 Safari/537.36'
          }
      ).with_indifferent_access
    end

    it 'should add context data' do
      @context_data_transformer.transform(
          original_event,
          @processing_units,
          @load_commands,
          @pipeline_ctx
      )

      expect(@processing_units.length).to eq(1)
      in_context = @processing_units[0][:in_context]
      expect(in_context).to include(:platform => "Macintosh")
      expect(in_context).to include(:platform_version => "10.11.4")
      expect(in_context).to include(:runtime => "Chrome")
      expect(in_context).to include(:runtime_version => "50")
      expect(in_context).to include(:device => "Unknown")
    end
  end

end
