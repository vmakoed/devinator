class Ticket < ApplicationRecord
  belongs_to :mission

  validates :jira_key, presence: true
  validates :summary, presence: true
  validates :status, presence: true
  validates :jira_key, uniqueness: { scope: :mission_id }
  validates :complexity_score, inclusion: { in: 1..10 }, allow_nil: true
  validates :complexity_category, inclusion: { in: %w[low medium high] }, allow_nil: true

  before_create :generate_id

  scope :low_complexity, -> { where(complexity_category: "low") }
  scope :medium_complexity, -> { where(complexity_category: "medium") }
  scope :high_complexity, -> { where(complexity_category: "high") }
  scope :analyzed, -> { where.not(analyzed_at: nil) }
  scope :not_analyzed, -> { where(analyzed_at: nil) }

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

  private

  def generate_id
    self.id ||= SecureRandom.uuid
  end
end