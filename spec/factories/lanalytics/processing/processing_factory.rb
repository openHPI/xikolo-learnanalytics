FactoryBot.define do
  factory :load_command_with_entity, class: Lanalytics::Processing::LoadORM::CreateCommand do
    entity do
      Lanalytics::Processing::LoadORM::Entity.create(:dummy_type) do
        with_primary_attribute :dummy_uuid, :uuid, '1234567890'
        with_attribute :dummy_string_property, :string, 'dummy_string_value'
        with_attribute :dummy_int_property, :int, 1234
        with_attribute :dummy_float_property, :float, 1234.0
        with_attribute :dummy_timestamp_property, :timestamp, Time.parse('2015-03-10 09:00:00 +0100')
      end
    end

    initialize_with { new(entity) }
  end
end
