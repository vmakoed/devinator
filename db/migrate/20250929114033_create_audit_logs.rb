class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :session, null: false, foreign_key: true
      t.string :entity_type
      t.string :entity_id
      t.string :action
      t.text :old_values
      t.text :new_values
      t.references :user, null: false, foreign_key: true
      t.string :ip_address

      t.timestamps
    end
  end
end
