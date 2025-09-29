class Session < ApplicationRecord
  belongs_to :user
  has_many :jql_queries, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :assignments, dependent: :destroy
  has_many :session_configurations, dependent: :destroy
  has_many :audit_logs, dependent: :destroy

  validates :name, presence: true, length: { minimum: 3, maximum: 50 }
  validates :name, uniqueness: { scope: :user_id, message: "already exists for this user" }
  validates :status, presence: true, inclusion: { in: %w[active completed archived] }
  validates :user_id, presence: true

  before_validation :set_default_status, on: :create
  after_create :log_creation

  scope :active, -> { where(status: 'active') }
  scope :for_user, ->(user) { where(user: user) }

  def active?
    status == 'active'
  end

  def can_accept_queries?
    active?
  end

  def workspace_path
    "/sessions/#{id}/workspace"
  end

  def apply_configuration(config)
    return unless config.is_a?(SessionConfiguration)

    self.configuration = {
      jql_templates: config.jql_templates,
      complexity_settings: config.complexity_settings,
      notification_settings: config.notification_settings
    }.to_json
  end

  private

  def set_default_status
    self.status ||= 'active'
  end

  def log_creation
    audit_logs.create!(
      entity_type: 'Session',
      entity_id: id.to_s,
      action: 'create',
      new_values: attributes.to_json,
      user: user
    )
  end
end