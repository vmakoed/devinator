class AddAssignmentFieldsToMissions < ActiveRecord::Migration[8.0]
  def change
    add_column :missions, :assigned_at, :datetime
    add_column :missions, :assignment_completed_at, :datetime
    add_column :missions, :total_assigned_count, :integer, default: 0, null: false
    add_column :missions, :failed_assignment_count, :integer, default: 0, null: false
  end
end
