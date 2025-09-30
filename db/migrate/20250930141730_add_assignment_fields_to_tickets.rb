class AddAssignmentFieldsToTickets < ActiveRecord::Migration[8.0]
  def change
    add_column :tickets, :devin_session_id, :string
    add_column :tickets, :devin_session_url, :string
    add_column :tickets, :assigned_to_devin_at, :datetime
    add_column :tickets, :assignment_status, :string, default: "pending", null: false
    add_column :tickets, :assignment_error, :text
    add_column :tickets, :assignment_retry_count, :integer, default: 0, null: false
  end
end
