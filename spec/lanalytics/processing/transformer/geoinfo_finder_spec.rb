# frozen_string_literal: true

require 'rails_helper'

describe Lanalytics::Processing::Transformer::GeoinfoFinder do
  let(:original_event) do
    FactoryBot.attributes_for(:amqp_exp_stmt).with_indifferent_access
  end

  let(:processing_unit) { Lanalytics::Processing::Unit.new(:exp_event, original_event) }
  let(:processing_units) { [processing_unit] }
  let(:load_commands) { [] }
  let(:pipeline_ctx) { OpenStruct.new processing_action: :CREATE }
  let(:geoinfo_transformer) { described_class.new }

  it 'does nothing if there is no user ip' do
    geoinfo_transformer.transform(
      original_event,
      processing_units,
      load_commands,
      pipeline_ctx,
    )

    expect(processing_units).to match_array([processing_unit])
  end

  describe 'with a user ip' do
    let(:original_event) do
      FactoryBot.attributes_for(
        :amqp_exp_stmt,
        in_context: {user_ip: '123.21.23.1'},
      ).with_indifferent_access
    end

    it 'adds info' do
      geoinfo_transformer.transform(
        original_event,
        processing_units,
        load_commands,
        pipeline_ctx,
      )

      expect(processing_units.length).to eq(1)
      in_context = processing_units[0][:in_context]
      expect(in_context).to have_key(:user_location_city)
      expect(in_context).to have_key(:user_location_country_name)
      expect(in_context).to have_key(:user_location_country_code)
      expect(in_context).to have_key(:user_location_latitude)
      expect(in_context).to have_key(:user_location_longitude)
    end
  end
end
