class Ticket < ApplicationRecord
  belongs_to :mission

  validates :jira_key, presence: true
  validates :summary, presence: true
  validates :status, presence: true
  validates :jira_key, uniqueness: { scope: :mission_id }
  validates :complexity_score, inclusion: { in: 1..10 }, allow_nil: true
  validates :complexity_category, inclusion: { in: %w[low medium high] }, allow_nil: true
  validates :assignment_status, inclusion: { in: %w[pending assigned failed timeout] }

  before_create :generate_id

  scope :low_complexity, -> { where(complexity_category: "low") }
  scope :medium_complexity, -> { where(complexity_category: "medium") }
  scope :high_complexity, -> { where(complexity_category: "high") }
  scope :analyzed, -> { where.not(analyzed_at: nil) }
  scope :not_analyzed, -> { where(analyzed_at: nil) }
  scope :selected_for_assignment, -> { where(selected_for_assignment: true) }
  scope :not_selected, -> { where(selected_for_assignment: false) }
  scope :assigned_to_devin, -> { where(assignment_status: "assigned") }
  scope :assignment_failed, -> { where(assignment_status: "failed") }
  scope :assignment_timeout, -> { where(assignment_status: "timeout") }
  scope :assignment_pending, -> { where(assignment_status: "pending") }

  def analyzed?
    analyzed_at.present?
  end

  def low_complexity?
    complexity_category == "low"
  end

  def medium_complexity?
    complexity_category == "medium"
  end

  def high_complexity?
    complexity_category == "high"
  end

  def selected?
    selected_for_assignment
  end

  def select_for_assignment!
    update!(selected_for_assignment: true, selected_at: Time.current)
  end

  def deselect_for_assignment!
    update!(selected_for_assignment: false, selected_at: nil)
  end

  def assigned_to_devin?
    assignment_status == "assigned"
  end

  def assignment_failed?
    assignment_status == "failed"
  end

  def assignment_timeout?
    assignment_status == "timeout"
  end

  def assignment_pending?
    assignment_status == "pending"
  end

  def assign_to_devin!(session_id:, session_url:)
    update!(
      devin_session_id: session_id,
      devin_session_url: session_url,
      assigned_to_devin_at: Time.current,
      assignment_status: "assigned"
    )
  end

  def mark_assignment_failed!(error_message)
    update!(
      assignment_status: "failed",
      assignment_error: error_message,
      assignment_retry_count: assignment_retry_count + 1
    )
  end

  def mark_assignment_timeout!
    update!(
      assignment_status: "timeout",
      assignment_retry_count: assignment_retry_count + 1
    )
  end

  def jira_url
    return nil unless jira_key.present?
    base_url = ENV["JIRA_BASE_URL"]
    "#{base_url}/browse/#{jira_key}"
  end

  private

  def generate_id
    self.id ||= SecureRandom.uuid
  end
end