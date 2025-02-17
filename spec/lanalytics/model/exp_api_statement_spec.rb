# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lanalytics::Model::ExpApiStatement do
  subject(:statement) do
    described_class.new(
      user, verb, resource, timestamp,
      {result: 1000},
      {location: 'Potsdam'}
    )
  end

  let(:user) { Lanalytics::Model::StmtUser.new('00000003-3100-4444-9999-1234567890') }
  let(:verb) { Lanalytics::Model::StmtVerb.new('SOME_VERB') }
  let(:resource) do
    Lanalytics::Model::StmtResource.new(
      'SomeResource', '00000003-3100-4444-9999-0987654321',
      propertyA: 'property1', propertyB: 'property2'
    )
  end
  let(:timestamp) { Time.zone.parse('8 May 1989 05:00:00').to_datetime }

  describe '(Initialization)' do
    it 'initializes correctly' do
      expect(statement.user).to be user
      expect(statement.verb).to be verb
      expect(statement.resource).to be resource
      expect(statement.timestamp).to eq timestamp
      expect(statement.with_result).to eq(result: 1000)
      expect(statement.in_context).to eq(location: 'Potsdam')
    end

    it 'builds a hash of properties' do
      expect(statement).to respond_to(:properties)
      expect(statement.properties).to be_a(Hash)
      expect(statement.properties).to include(timestamp: timestamp.rfc3339)
      expect(statement.properties).to include(with_result: {result: 1000})
      expect(statement.properties).to include(in_context: {location: 'Potsdam'})
    end

    it 'initializes even when context and result missing' do
      stmt = described_class.new(user, verb, resource, timestamp)
      expect(stmt.with_result).to be_empty
      expect(stmt.in_context).to be_empty
    end

    context 'when "uuid" of stmt_user is empty' do
      let(:user) { Lanalytics::Model::StmtUser.new('') }

      it 'does not initialize' do
        expect { statement }.to raise_error(ArgumentError)
      end
    end

    context 'when "type" of stmt_resource is empty' do
      let(:resource) { Lanalytics::Model::StmtResource.new('', '') }

      it 'does not initialize' do
        expect { statement }.to raise_error(ArgumentError)
      end
    end

    context 'when a critical component (user, verb, resource) is missing' do
      subject(:statement) { described_class.new('', '', '') }

      it 'does not initialize' do
        expect { statement }.to raise_error(ArgumentError)
      end
    end

    it 'does not initialize when some combination of critical components is missing' do
      7.times do |i|
        user = nil unless i.anybits?(1)
        verb = nil unless i.anybits?(2)
        resource = nil unless i.anybits?(4)

        failure_message = "user: #{user ? 'not nil' : 'nil'}, verb: #{verb ? 'not nil' : 'nil'}, resource: #{resource ? 'not nil' : 'nil'}"

        expect do
          described_class.new(user, verb, resource)
        end.to raise_error(ArgumentError), failure_message
      end
    end

    it 'does not initialize when all critical components are missing' do
      expect do
        described_class.new(nil, nil, nil, nil, {result: 1000}, {location: 'Potsdam'})
      end.to raise_error(ArgumentError)
    end

    it 'does not initialize timestamp as current datetime when timestamp not defined' do
      stmt = described_class.new(user, verb, resource)
      expect(stmt.timestamp).to be_within(1000).of(Time.zone.now.to_datetime)
    end

    it 'does not initialize timestamp as current datetime when timestamp nil' do
      stmt = described_class.new(user, verb, resource, nil)
      expect(stmt.timestamp).to be_within(1000).of(Time.zone.now.to_datetime)
    end

    it 'understands a proper date time string' do
      stmt = described_class.new(user, verb, resource, '8 May 1989 05:00:00')
      expect(stmt.timestamp).to eq Time.zone.parse('8 May 1989 05:00:00').to_datetime
    end

    it 'does not initialize with an invalid date time string' do
      expect do
        described_class.new(user, verb, resource, 'openhpi')
      end.to raise_error(ArgumentError)
    end
  end

  describe '(JSON De-/Serialization)' do
    let(:statement_hash) do
      {
        user: {uuid: '00000003-3100-4444-9999-1234567890'},
        verb: {type: 'SOME_VERB'},
        resource: {
          type: 'SomeResource',
          uuid: '00000003-3100-4444-9999-0987654321',
          properties: {propertyA: 'property1', propertyB: 'property2'},
        },
        timestamp: Time.zone.parse('8 May 1989 05:00:00').to_datetime,
        with_result: {result: 1000},
        in_context: {location: 'Potsdam'},
      }
    end

    it 'accepts JSON hash' do
      stmt = described_class.new_from_json(statement_hash)

      expect(stmt).to be_a described_class

      expect(stmt.user).to eq Lanalytics::Model::StmtUser.new('00000003-3100-4444-9999-1234567890')
      expect(stmt.verb).to eq Lanalytics::Model::StmtVerb.new('SOME_VERB')
      expect(stmt.resource).to eq resource
      expect(stmt.timestamp).to eq timestamp
    end

    it 'accepts JSON string' do
      stmt_json_str = JSON.dump(statement_hash)
      stmt = described_class.new_from_json(stmt_json_str)

      expect(stmt).to be_a described_class

      expect(stmt.user).to eq Lanalytics::Model::StmtUser.new('00000003-3100-4444-9999-1234567890')
      expect(stmt.verb).to eq Lanalytics::Model::StmtVerb.new('SOME_VERB')
      expect(stmt.resource).to eq resource
      expect(stmt.timestamp).to eq timestamp
    end

    it 'from nil should raise error' do
      expect { described_class.new_from_json(nil) }.to raise_error(ArgumentError)
    end

    it 'can be dumped to JSON' do
      dump = JSON.dump(statement)

      expect(JSON.parse(dump)).to include(
        'json_class' => 'Lanalytics::Model::ExpApiStatement',
        'data' => {
          'user' => {'type' => 'USER', 'uuid' => '00000003-3100-4444-9999-1234567890'},
          'verb' => {'type' => 'SOME_VERB'},
          'resource' => {'type' => 'SOMERESOURCE', 'uuid' => '00000003-3100-4444-9999-0987654321'},
          'timestamp' => '1989-05-08T05:00:00+00:00',
          'with_result' => {'result' => 1000},
          'in_context' => {'location' => 'Potsdam'},
        },
      )
    end
  end

  describe '(Marshalling)' do
    it 'marshals the objects' do
      marshalled_stmt = Marshal.dump(statement)
      expect(marshalled_stmt).to be_a(String)
      expect(marshalled_stmt).to include('Lanalytics::Model::ExpApiStatement')
      expect(marshalled_stmt).to include('Lanalytics::Model::StmtUser')
      expect(marshalled_stmt).to include('Lanalytics::Model::StmtVerb')
      expect(marshalled_stmt).to include('Lanalytics::Model::StmtResource')
    end

    it 'can do the whole cycle' do
      new_stmt = Marshal.load(Marshal.dump(statement))
      expect(new_stmt).to be_a described_class
      expect(new_stmt).not_to be(statement)
      expect(new_stmt).to eq(statement)
    end
  end
end
