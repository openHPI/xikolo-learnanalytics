# frozen_string_literal: true

require 'rails_helper'

describe 'Elasticsearch Health Check' do # rubocop:disable RSpec/DescribeClass
  before do
    Msgr.client.start

    # first ping request will fail, second succeeds
    stub_request(:head, 'http://localhost:9200/')
      .to_return(
        {status: 503},
        {status: 200},
      )
  end

  it 'retries until elasticsearch is available again' do
    Msgr.publish(attributes_for(:amqp_exp_stmt).with_indifferent_access, to: 'xikolo.web.exp_event.create')

    # the consumer should be executed twice
    Msgr::TestPool.run count: 2
  end
end
