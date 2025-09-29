class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :session_configurations, dependent: :destroy
  has_many :complexity_analyses, foreign_key: 'overridden_by_user_id', dependent: :nullify
  has_many :assignments, foreign_key: 'created_by_user_id', dependent: :destroy
  has_many :complexity_criteria, foreign_key: 'created_by_user_id', dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :jql_queries, through: :sessions

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :role, presence: true, inclusion: { in: %w[admin team_lead developer] }
  validates :password_hash, presence: true

  scope :active, -> { where(is_active: true) }
  scope :team_leads, -> { where(role: %w[team_lead admin]) }

  def can_create_sessions?
    %w[team_lead admin].include?(role)
  end

  def active_sessions
    sessions.where(status: 'active')
  end

  def can_create_new_session?
    can_create_sessions? && active_sessions.count < 5
  end

  def default_session_configuration
    session_configurations.where(is_default: true).first
  end
end