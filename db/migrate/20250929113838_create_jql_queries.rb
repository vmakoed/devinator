class CreateJqlQueries < ActiveRecord::Migration[8.0]
  def change
    create_table :jql_queries do |t|
      t.references :session, null: false, foreign_key: true
      t.text :query_text
      t.datetime :executed_at
      t.string :status
      t.integer :ticket_count
      t.text :parameters

      t.timestamps
    end
  end
end
