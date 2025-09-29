class CreateMissions < ActiveRecord::Migration[8.0]
  def change
    create_table :missions do |t|
      t.string :name
      t.string :status

      t.timestamps
    end
  end
end
