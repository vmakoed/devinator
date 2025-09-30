class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets, id: :string do |t|
      t.string :mission_id, null: false
      t.string :jira_key, null: false
      t.string :summary, null: false
      t.text :description
      t.string :status, null: false
      t.string :priority
      t.string :assignee
      t.text :labels
      t.datetime :jira_created_at
      t.json :raw_data

      t.timestamps
    end

    add_index :tickets, :mission_id
    add_index :tickets, [:mission_id, :jira_key], unique: true
    add_foreign_key :tickets, :missions
  end
end
