require 'rails_helper'

RSpec.describe Lanalytics::Model::StmtResource do
  describe 'initialization' do
    it "can not initialize when 'type' or 'uuid' are nil or empty" do
      expect { described_class.new(nil, nil) }.to raise_error(ArgumentError)
      expect { described_class.new('User', nil) }.to raise_error(ArgumentError)
      expect { described_class.new('User', '') }.to raise_error(ArgumentError)
      expect { described_class.new(nil, '1231451') }.to raise_error(ArgumentError)
      expect { described_class.new('', '1231451') }.to raise_error(ArgumentError)
    end

    it 'new_from_json with nil raises an error' do
      expect { described_class.new_from_json(nil) }.to raise_error(ArgumentError)
    end
  end

  describe '(JSON De-/Serialization)' do
    let(:resource_hash) do
      {
        type: 'SomeResource',
        uuid: '00000003-3100-4444-9999-0987654321',
        properties: {
          propertyA: 'property1',
          propertyB: 'property2',
        },
      }
    end

    it 'accepts JSON hash' do
      resource = described_class.new_from_json(resource_hash)
      expect(resource).to be_a described_class
      expect(resource.type).to eq :SOMERESOURCE
      expect(resource.uuid).to eq '00000003-3100-4444-9999-0987654321'
    end

    it 'accepts JSON string' do
      resource = described_class.new_from_json(JSON.dump(resource_hash))
      expect(resource).to be_a described_class
      expect(resource.type).to eq :SOMERESOURCE
      expect(resource.uuid).to eq '00000003-3100-4444-9999-0987654321'
    end

    it 'can be dumped to JSON' do
      resource = described_class.new(
        'SomeResource', '00000003-3100-4444-9999-0987654321',
        propertyA: 'property1',
        propertyB: 'property2'
      )
      resource_json_str = JSON.dump(resource)
      expect(resource_json_str).to be_a String
      expect(JSON.parse(resource_json_str)).to include(
        'json_class' => 'Lanalytics::Model::StmtResource',
        'data' => {'type' => 'SOMERESOURCE', 'uuid' => resource.uuid.to_s},
      )
    end
  end
end
