class CreateAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :assignments do |t|
      t.references :session, null: false, foreign_key: true
      t.references :ticket, null: false, foreign_key: true
      t.string :assignee_type
      t.string :assignee_id
      t.datetime :assigned_at
      t.string :status
      t.text :assignment_message
      t.text :assignment_metadata
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
