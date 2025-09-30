class Ticket < ApplicationRecord
  belongs_to :mission

  validates :jira_key, presence: true
  validates :summary, presence: true
  validates :status, presence: true
  validates :jira_key, uniqueness: { scope: :mission_id }

  before_create :generate_id

  private

  def generate_id
    self.id ||= SecureRandom.uuid
  end
end