class Mission < ApplicationRecord
  has_many :tickets, dependent: :destroy

  validates :name, presence: true
  validates :status, presence: true
  validates :jql_query, presence: true, if: :jql_query_required?

  scope :draft, -> { where(status: 'draft') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :analyzed, -> { where(status: 'analyzed') }

  def self.generate_name
    "Mission - #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
  end

  def save_jql_query!(query)
    self.jql_query = query
    self.status = 'in_progress' if status == 'draft'
    save!
  end

  private

  def jql_query_required?
    status == 'in_progress' || jql_query.present?
  end
end
