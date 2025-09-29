class AuditLog < ApplicationRecord
  belongs_to :session
  belongs_to :user

  validates :entity_type, presence: true
  validates :entity_id, presence: true
  validates :action, presence: true
  validates :user_id, presence: true
  validates :session_id, presence: true

  scope :for_entity, ->(type, id) { where(entity_type: type, entity_id: id) }
  scope :recent, -> { order(created_at: :desc) }

  def entity_changed?
    old_values.present? && new_values.present?
  end

  def parsed_old_values
    JSON.parse(old_values || '{}')
  rescue JSON::ParserError
    {}
  end

  def parsed_new_values
    JSON.parse(new_values || '{}')
  rescue JSON::ParserError
    {}
  end

  def changes_summary
    return "Created" if old_values.blank?
    return "Deleted" if new_values.blank?

    old_data = parsed_old_values
    new_data = parsed_new_values

    changed_fields = []
    new_data.each do |key, new_value|
      old_value = old_data[key]
      changed_fields << key if old_value != new_value
    end

    "Updated: #{changed_fields.join(', ')}"
  end
end