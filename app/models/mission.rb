class Mission < ApplicationRecord
  validates :name, presence: true
  validates :status, presence: true

  scope :draft, -> { where(status: 'draft') }

  def self.generate_name
    "Mission - #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
  end
end
