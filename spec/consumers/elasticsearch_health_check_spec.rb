# frozen_string_literal: true

require 'rails_helper'

describe 'Elasticsearch Health Check' do # rubocop:disable RSpec/DescribeClass
  let!(:elastic_stub) do
    # First ping request will fail, second succeeds
    stub_request(:head, 'http://localhost:9200/')
      .to_return(
        {status: 503, body: +''},
        {status: 200, body: +''},
      )
  end

  before { Msgr.client.start }

  it 'retries until Elasticsearch is available again' do
    Msgr.publish(attributes_for(:amqp_exp_stmt).with_indifferent_access, to: 'xikolo.web.exp_event.create')

    # The consumer should be executed twice
    Msgr::TestPool.run count: 2
    expect(elastic_stub).to have_been_requested.twice
  end
end
