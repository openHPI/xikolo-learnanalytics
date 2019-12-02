require 'rails_helper'

RSpec.describe Lanalytics::Model::StmtUser do
  it 'initializes correctly' do
    stmt_user = described_class.new('1234567890')
    expect(stmt_user.type).to eq :USER
    expect(stmt_user.uuid).to eq '1234567890'
  end

  describe '(JSON De-/Serialization)' do
    it 'accepts JSON hash' do
      stmt_user = described_class.new_from_json(uuid: '00000003-3100-4444-9999-1234567890')
      expect(stmt_user).to be_a described_class
      expect(stmt_user.type).to eq :USER
      expect(stmt_user.uuid).to eq '00000003-3100-4444-9999-1234567890'
    end

    it 'accepts JSON string' do
      stmt_user = described_class.new_from_json(JSON.dump(uuid: '00000003-3100-4444-9999-1234567890'))
      expect(stmt_user).to be_a described_class
      expect(stmt_user.type).to eq :USER
      expect(stmt_user.uuid).to eq '00000003-3100-4444-9999-1234567890'
    end

    it 'can be dumped to JSON' do
      stmt_user = described_class.new '00000003-3100-4444-9999-1234567890'
      stmt_user_json_str = JSON.dump(stmt_user)
      expect(stmt_user_json_str).to be_a String
      expect(JSON.parse(stmt_user_json_str)).to include(
        'json_class' => 'Lanalytics::Model::StmtUser',
        'data' => {'type' => 'USER', 'uuid' => '00000003-3100-4444-9999-1234567890'},
      )
    end
  end
end
