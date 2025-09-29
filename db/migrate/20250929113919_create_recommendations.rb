class CreateRecommendations < ActiveRecord::Migration[8.0]
  def change
    create_table :recommendations do |t|
      t.references :session, null: false, foreign_key: true
      t.references :ticket, null: false, foreign_key: true
      t.string :recommendation_type
      t.decimal :confidence_score
      t.text :reasoning
      t.boolean :is_suitable_for_devin
      t.text :recommendation_details

      t.timestamps
    end
  end
end
