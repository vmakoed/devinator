class AddSelectionFieldsToTickets < ActiveRecord::Migration[8.0]
  def change
    add_column :tickets, :selected_for_assignment, :boolean, default: false, null: false
    add_column :tickets, :selected_at, :datetime
  end
end
