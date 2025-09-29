class JqlQuery < ApplicationRecord
  belongs_to :session
  has_one :user, through: :session

  validates :query_text, presence: true, length: { maximum: 2000 }
  validates :session_id, presence: true
  validates :status, inclusion: { in: %w[pending executing completed failed] }

  # Custom validation for JQL syntax
  validate :validate_jql_syntax

  before_validation :set_default_values, on: :create
  after_create :log_creation

  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { order(created_at: :desc) }

  def display_name
    name.presence || "Query #{id}"
  end

  def formatted_query
    query_text&.strip
  end

  def ready_for_execution?
    status == 'pending' && query_text.present?
  end

  def can_execute?
    ready_for_execution? && session.active?
  end

  def execute!
    return false unless can_execute?

    update!(status: 'executing', executed_at: Time.current)

    begin
      # This will be implemented in UC003 for actual JIRA integration
      # For now, we just mark as completed
      update!(status: 'completed', ticket_count: 0)
      log_execution
      true
    rescue => e
      update!(status: 'failed')
      Rails.logger.error "JQL Query execution failed: #{e.message}"
      false
    end
  end

  def execution_summary
    return "Not executed" unless executed_at

    case status
    when 'completed'
      "Executed at #{executed_at.strftime('%Y-%m-%d %H:%M')} - #{ticket_count || 0} tickets found"
    when 'failed'
      "Failed at #{executed_at.strftime('%Y-%m-%d %H:%M')}"
    when 'executing'
      "Currently executing..."
    else
      "Status: #{status}"
    end
  end

  # Check if this query is similar to existing queries in the session
  def similar_queries
    return JqlQuery.none unless query_text.present?

    session.jql_queries
           .where.not(id: id)
           .where("query_text LIKE ?", "%#{query_text.split.first}%")
           .limit(3)
  end

  private

  def set_default_values
    self.status ||= 'pending'
  end

  def validate_jql_syntax
    return if query_text.blank?

    # Basic JQL syntax validation
    validation_result = JqlValidator.validate(query_text)

    unless validation_result[:valid]
      errors.add(:query_text, validation_result[:error])
    end
  end

  def log_creation
    session.audit_logs.create!(
      entity_type: 'JqlQuery',
      entity_id: id.to_s,
      action: 'create',
      new_values: attributes.to_json,
      user: session.user
    )
  rescue => e
    Rails.logger.warn "Failed to log JQL query creation: #{e.message}"
  end

  def log_execution
    session.audit_logs.create!(
      entity_type: 'JqlQuery',
      entity_id: id.to_s,
      action: 'execute',
      new_values: {
        executed_at: executed_at,
        status: status,
        ticket_count: ticket_count
      }.to_json,
      user: session.user
    )
  rescue => e
    Rails.logger.warn "Failed to log JQL query execution: #{e.message}"
  end
end