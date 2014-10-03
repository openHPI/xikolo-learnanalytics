class CreateRessources < ActiveRecord::Migration
  def change
    create_table :ressources do |t|

      t.timestamps
    end
  end
end
