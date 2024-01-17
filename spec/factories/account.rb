# frozen_string_literal: true

FactoryBot.define do
  factory 'account:root', class: Hash do
    user_url { '/users/{id}' }
    users_url { '/users' }

    group_url { '/groups/{id}' }
    groups_url { '/groups' }

    initialize_with { attributes.as_json }
  end

  factory 'account:user', class: Hash do
    id { SecureRandom.uuid }

    url { "/users/#{id}" }
    groups_url { Stub.url(:account, "/users/#{id}/groups") }

    initialize_with { attributes.as_json }
  end
end
