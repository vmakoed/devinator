class SessionConfiguration < ApplicationRecord
  belongs_to :session
  belongs_to :user

  validates :configuration_name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :configuration_name, uniqueness: { scope: :user_id, message: "already exists for this user" }
  validate :only_one_default_per_user

  scope :for_user, ->(user) { where(user: user) }
  scope :defaults, -> { where(is_default: true) }

  def mark_as_default!
    transaction do
      user.session_configurations.update_all(is_default: false)
      update!(is_default: true)
    end
  end

  def parsed_jql_templates
    JSON.parse(jql_templates || '[]')
  rescue JSON::ParserError
    []
  end

  def parsed_complexity_settings
    JSON.parse(complexity_settings || '{}')
  rescue JSON::ParserError
    {}
  end

  def parsed_notification_settings
    JSON.parse(notification_settings || '{}')
  rescue JSON::ParserError
    {}
  end

  private

  def only_one_default_per_user
    return unless is_default?

    existing_default = user.session_configurations.defaults.where.not(id: id).exists?
    errors.add(:is_default, "can only have one default configuration") if existing_default
  end
end