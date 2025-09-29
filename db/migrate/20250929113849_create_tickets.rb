class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.references :session, null: false, foreign_key: true
      t.string :jira_key
      t.string :jira_id
      t.string :title
      t.text :description
      t.string :status
      t.string :priority
      t.string :issue_type
      t.text :labels
      t.string :assignee
      t.string :reporter
      t.datetime :created_date
      t.datetime :updated_date
      t.text :raw_data

      t.timestamps
    end
  end
end
