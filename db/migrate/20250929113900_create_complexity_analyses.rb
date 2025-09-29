class CreateComplexityAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :complexity_analyses do |t|
      t.references :ticket, null: false, foreign_key: true
      t.decimal :complexity_score
      t.string :complexity_level
      t.text :scoring_details
      t.text :heuristics_applied
      t.datetime :analyzed_at
      t.string :analysis_version
      t.boolean :is_manual_override
      t.text :override_reason
      t.references :overridden_by_user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
