class CreateComplexityCriteria < ActiveRecord::Migration[8.0]
  def change
    create_table :complexity_criteria do |t|
      t.string :name
      t.text :description
      t.text :criteria_config
      t.decimal :weight
      t.boolean :is_active
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
