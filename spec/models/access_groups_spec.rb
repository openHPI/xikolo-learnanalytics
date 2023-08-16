# frozen_string_literal: true

require 'rails_helper'

describe AccessGroups do
  let(:access_groups) { described_class.new }
  let(:user_id1) { '98098dfd-dbe1-4897-888a-c919fe64d727' }
  let(:user_id2) { '7790394d-e9e5-404c-97a9-0d4aa7a15160' }
  let(:user_id3) { '6dcea948-b486-4e59-981e-c028883154dd' }

  before do
    Stub.request(:account, :get)
      .to_return Stub.json({groups_url: '/groups'})

    Stub.request(
      :account, :get, '/groups', query: {tag: 'access'}
    ).to_return Stub.json([
      {
        name: 'xikolo.affiliated',
        memberships_url: '/groups/xikolo.affiliated/memberships',
      },
    ], links: {next: '/groups?tag=access&page=2'})
    Stub.request(
      :account, :get, '/groups',
      query: {tag: 'access', page: 2}
    ).to_return Stub.json([
      {
        name: 'opensap.partner',
        memberships_url: '/groups/opensap.partner/memberships',
      },
    ])

    Stub.request(
      :account, :get, '/groups/xikolo.affiliated/memberships',
      query: {per_page: 10_000}
    ).to_return Stub.json([{user: user_id2}], links: {
      next: '/groups/xikolo.affiliated/memberships?per_page=10000&page=2',
    })
    Stub.request(
      :account, :get, '/groups/xikolo.affiliated/memberships',
      query: {per_page: 10_000, page: 2}
    ).to_return Stub.json([{user: user_id3}])
    Stub.request(
      :account, :get, '/groups/opensap.partner/memberships',
      query: {per_page: 10_000}
    ).to_return Stub.json([{user: user_id3}])
  end

  describe '#memberships' do
    subject { access_groups.memberships_for(user_id) }

    context 'user with no access groups' do
      let(:user_id) { user_id1 }

      it { is_expected.to eq(%w[]) }
    end

    context 'user with one access group' do
      let(:user_id) { user_id2 }

      it { is_expected.to eq(%w[xikolo.affiliated]) }
    end

    context 'user with two access groups' do
      let(:user_id) { user_id3 }

      it { is_expected.to eq(%w[xikolo.affiliated opensap.partner]) }
    end
  end
end
