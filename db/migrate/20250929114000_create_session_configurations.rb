class CreateSessionConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :session_configurations do |t|
      t.references :session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :configuration_name
      t.text :jql_templates
      t.text :complexity_settings
      t.text :notification_settings
      t.boolean :is_default

      t.timestamps
    end
  end
end
