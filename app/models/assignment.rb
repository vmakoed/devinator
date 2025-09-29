class Assignment < ApplicationRecord
  belongs_to :session
  belongs_to :ticket

  validates :session_id, presence: true
  validates :ticket_id, presence: true
end