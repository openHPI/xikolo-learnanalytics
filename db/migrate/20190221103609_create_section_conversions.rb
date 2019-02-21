class CreateSectionConversions < ActiveRecord::Migration[5.2]
  def change
    create_table :section_conversions, id: :uuid do |t|
      t.uuid :course_id
      t.jsonb :data
    end
  end
end
