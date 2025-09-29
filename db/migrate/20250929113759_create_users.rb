class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :name
      t.string :password_hash
      t.string :role
      t.text :jira_credentials
      t.text :preferences
      t.boolean :is_active

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
