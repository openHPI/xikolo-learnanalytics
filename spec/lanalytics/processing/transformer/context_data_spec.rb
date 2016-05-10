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

  describe 'with a user-agent' do
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
      expect(in_context).to have_key(:platform)
      expect(in_context).to have_key(:platform_version)
      expect(in_context).to have_key(:runtime)
      expect(in_context).to have_key(:runtime_version)
      expect(in_context).to have_key(:device)
    end
  end

end
