FactoryGirl.define do

  factory :dummy_punit, class: Lanalytics::Processing::Unit do
    type(:dummy_type)
    data(dummy_prop1: 'dummy_value1',
         dummy_prop2: 'dummy_value2',
         dummy_prop3: 'dummy_value3')

    initialize_with { new(type, data) }

  end

  factory :load_command_with_entity, class: Lanalytics::Processing::LoadORM::MergeEntityCommand do
    entity(Lanalytics::Processing::LoadORM::Entity.create(:dummy_type) do
    
      with_primary_attribute :dummy_uuid, :uuid, '1234567890'

      with_attribute :dummy_string_property, :string, 'dummy_string_value'
      with_attribute :dummy_int_property, :int, 1234
      with_attribute :dummy_float_property, :float, 1234.0
      with_attribute :dummy_timestamp_property, :timestamp, Time.parse('2015-03-10 09:00:00 +0100')
    end)

    initialize_with { new(entity) }
  end
  
end