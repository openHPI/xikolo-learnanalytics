require 'rails_helper'

describe Lanalytics::Processing::Transformer::AnonymousDataFilter do

  before(:each) do
    @original_hash_ipv4 = FactoryBot.attributes_for(:amqp_user_with_ipv4).with_indifferent_access
    @original_hash_ipv6 = FactoryBot.attributes_for(:amqp_user_with_ipv6).with_indifferent_access
    @processing_units_ipv4 = [ Lanalytics::Processing::Unit.new(:USER, @original_hash_ipv4) ]
    @processing_units_ipv6 = [ Lanalytics::Processing::Unit.new(:USER, @original_hash_ipv6) ]
  end

  describe 'with ip anonymization enabled' do
    before(:each) do
      @data_filter = Lanalytics::Processing::Transformer::AnonymousDataFilter.new(anonymize_ip: true)
    end

    it 'should remove all sensitive data properties' do

      @data_filter.transform(@original_hash_ipv4, @processing_units_ipv4, [], nil)

      expect(@processing_units_ipv4.length).to eq(1)
      processing_unit = @processing_units_ipv4.first
      expect(processing_unit.data).to include(language: "en", born_at: "1985-04-24T00:00:00.000Z")
      expect(processing_unit.data.keys).to_not include(:email, :display_name, :first_name, :last_name)
    end

    it 'should anonymize IPv4 addresses' do

      @data_filter.transform(@original_hash_ipv4, @processing_units_ipv4, [], nil)

      expect(@processing_units_ipv4.length).to eq(1)
      processing_unit = @processing_units_ipv4.first
      expect(processing_unit.data[:in_context]).to include(user_ip: "141.89.0.0")

    end

    it 'should anonymize IPv6 addresses' do

      @data_filter.transform(@original_hash_ipv6, @processing_units_ipv6, [], nil)

      expect(@processing_units_ipv6.length).to eq(1)
      processing_unit = @processing_units_ipv6.first
      expect(processing_unit.data[:in_context]).to include(user_ip: "2001:638:800::")

    end

    it 'should not modify the original hash' do
      old_hash = @original_hash_ipv4
      @data_filter.transform(@original_hash_ipv4, @processing_units_ipv4, [], nil)
      expect(@original_hash_ipv4).to be(old_hash)
      expect(@original_hash_ipv4).to eq(old_hash)
    end
  end

  describe 'with ip anonymization disabled' do
    before(:each) do
      @data_filter = Lanalytics::Processing::Transformer::AnonymousDataFilter.new(anonymize_ip: false)
    end

    it 'should remove all sensitive data properties' do

      @data_filter.transform(@original_hash_ipv4, @processing_units_ipv4, [], nil)

      expect(@processing_units_ipv4.length).to eq(1)
      processing_unit = @processing_units_ipv4.first
      expect(processing_unit.data).to include(language: "en", born_at: "1985-04-24T00:00:00.000Z")
      expect(processing_unit.data.keys).to_not include(:email, :display_name, :first_name, :last_name)
    end

    it 'should not anonymize IPv4 addresses' do

      @data_filter.transform(@original_hash_ipv4, @processing_units_ipv4, [], nil)

      expect(@processing_units_ipv4.length).to eq(1)
      processing_unit = @processing_units_ipv4.first
      expect(processing_unit.data[:in_context]).to include(user_ip: "141.89.225.126")

    end

    it 'should not anonymize IPv6 addresses' do

      @data_filter.transform(@original_hash_ipv6, @processing_units_ipv6, [], nil)

      expect(@processing_units_ipv6.length).to eq(1)
      processing_unit = @processing_units_ipv6.first
      expect(processing_unit.data[:in_context]).to include(user_ip: "2001:638:807:204::8d59:e17e")

    end

    it 'should not modify the original hash' do
      old_hash = @original_hash_ipv4
      @data_filter.transform(@original_hash_ipv4, @processing_units_ipv4, [], nil)
      expect(@original_hash_ipv4).to be(old_hash)
      expect(@original_hash_ipv4).to eq(old_hash)
    end
  end

end