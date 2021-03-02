# frozen_string_literal: true

require 'rails_helper'

describe Lanalytics::Processing::Transformer::AnonymousDataFilter do
  subject(:filter) { described_class.new }

  let(:input) do
    {
      id: '00000001-3100-4444-9999-000000000001',
      email: 'kevin.cool@example.com',
      display_name: 'Kevin Cool',
      first_name: 'Kevin',
      last_name: 'Cool Jr.',
      name: 'Kevin Cool',
      full_name: 'Kevin Cool Jr.',
      language: 'en',
      timezone: nil,
      image_id: nil,
      born_at: '1985-04-24T00:00:00.000Z',
      archived: false,
      password_digest: '$2a$10$v93d1K4Jw8ur/Ki0Yz69ouSnjTielvB3eb4WZJ95V6yxPZSi/rcYy',
      created_at: '2014-10-20T19:56:31.268Z',
      confirmed: true,
      emails_url: 'http://account.xikolo.tld/users/00000001-3100-4444-9999-000000000001/emails',
      email_url: 'http://account.xikolo.tld/users/00000001-3100-4444-9999-000000000001/emails/{id}',
      self_url: 'http://account.xikolo.tld/users/00000001-3100-4444-9999-000000000001',
      blurb_url: 'http://account.xikolo.tld/users/00000001-3100-4444-9999-000000000001/blurb',
      affiliated: false,
      in_context: {
        user_ip: '141.89.225.126',
        user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.25 Safari/537.36',
      },
    }
  end
  let(:processing_units) { [Lanalytics::Processing::Unit.new(:USER, input)] }

  it 'removes all sensitive data properties' do
    filter.transform(input, processing_units, [], nil)

    processing_unit = processing_units.first
    expect(processing_unit.data).to include(language: 'en', born_at: '1985-04-24T00:00:00.000Z')
    expect(processing_unit.data).not_to include(:email, :display_name, :first_name, :last_name)
    expect(processing_unit.data[:in_context]).not_to include(:user_ip, :user_agent)
  end

  it 'does not modify the original hash' do
    input.freeze

    # This would raise a +FrozenError+ if the transformation actually affected
    # the original hash, e.g. by removing elements from it and not from a copy.
    expect do
      filter.transform(input, processing_units, [], nil)
    end.not_to raise_error
  end
end
