class AddComplexityFieldsToTickets < ActiveRecord::Migration[8.0]
  def change
    add_column :tickets, :complexity_score, :integer
    add_column :tickets, :complexity_category, :string
    add_column :tickets, :complexity_factors, :json
    add_column :tickets, :analyzed_at, :datetime
  end
end
