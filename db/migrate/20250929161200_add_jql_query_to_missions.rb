class AddJqlQueryToMissions < ActiveRecord::Migration[8.0]
  def change
    add_column :missions, :jql_query, :text
  end
end
