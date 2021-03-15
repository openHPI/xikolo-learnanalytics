# frozen_string_literal: true

namespace :xikolo do
  desc <<~DESC
    Creates admin role for this service and needed grants
  DESC
  task migrate_permissions: :environment do
    tries = 1

    begin
      service = Restify.new(:account).get.value!
    rescue Restify::NetworkError => e
      if (tries += 1) > 3
        warn "Account service unavailable: #{e}"
        exit 1
      else
        warn "Account service unavailable: #{e}\nWill retry in 5 seconds..."
        sleep 5
        retry
      end
    end

    # rubocop:disable Security/YAMLLoad
    data = YAML.load File.read 'config/permissions.yml'
    # rubocop:enable all

    data.fetch('groups', []).each do |group|
      puts "syncing group #{group['name']}"
      service.rel(:group).put(group, id: group['name']).value
    end

    data.fetch('roles', {}).each do |name, permissions|
      puts "syncing role #{name}"
      service.rel(:role).put({permissions: permissions}, {id: name}).value
    end

    data.fetch('grants', []).each do |grant|
      puts "syncing grant #{grant}"
      service.rel(:grants).post(grant).value
    end
  end
end
