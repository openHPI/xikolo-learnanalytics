# frozen_string_literal: true

require 'rails_helper'

describe AccessGroups do
  let(:access_groups) { described_class.new }
  let(:account_service) { Restify.new(:account).get.value! }
  let(:user_no_groups_data) { build(:'account:user') }
  let(:user_no_groups) { account_service.rel(:user).get({id: user_no_groups_data['id']}).value! }
  let(:user_one_group_data) { build(:'account:user') }
  let(:user_one_group) { account_service.rel(:user).get({id: user_one_group_data['id']}).value! }
  let(:user_two_groups_data) { build(:'account:user') }
  let(:user_two_groups) { account_service.rel(:user).get({id: user_two_groups_data['id']}).value! }

  before do
    Stub.request(:account, :get)
      .to_return Stub.json(build(:'account:root'))

    Stub.request(:account, :get, "/users/#{user_no_groups_data['id']}")
      .to_return Stub.json(user_no_groups_data)
    Stub.request(:account, :get, "/users/#{user_one_group_data['id']}")
      .to_return Stub.json(user_one_group_data)
    Stub.request(:account, :get, "/users/#{user_two_groups_data['id']}")
      .to_return Stub.json(user_two_groups_data)

    Stub.request(
      :account, :get, "/users/#{user_no_groups_data['id']}/groups", query: {per_page: 1000}
    ).to_return Stub.json([])
    Stub.request(
      :account, :get, "/users/#{user_one_group_data['id']}/groups", query: {per_page: 1000}
    ).to_return Stub.json([
      {
        name: 'xikolo.affiliated',
      },
    ])
    Stub.request(
      :account, :get, "/users/#{user_two_groups_data['id']}/groups", query: {per_page: 1000}
    ).to_return Stub.json([
      {
        name: 'xikolo.affiliated',
      },
    ])

    Stub.request(
      :account, :get, '/groups', query: {tag: 'access'}
    ).to_return Stub.json([
      {
        name: 'xikolo.affiliated',
        memberships_url: '/groups/xikolo.affiliated/memberships',
      },
    ])
  end

  describe '#memberships' do
    subject { access_groups.memberships_for(user) }

    context 'user with no access groups' do
      let(:user) { user_no_groups }

      it { is_expected.to eq(%w[]) }
    end

    context 'user with one access group' do
      let(:user) { user_one_group }

      it { is_expected.to eq(%w[xikolo.affiliated]) }
    end

    context 'user with two access groups' do
      let(:user) { user_two_groups }

      it { is_expected.to eq(%w[xikolo.affiliated]) }
    end
  end
end
