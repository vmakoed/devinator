class AddNameAndDescriptionToJqlQueries < ActiveRecord::Migration[8.0]
  def change
    add_column :jql_queries, :name, :string
    add_column :jql_queries, :description, :text
  end
end
