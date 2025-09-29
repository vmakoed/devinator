class Ticket < ApplicationRecord
  belongs_to :session

  validates :jira_key, presence: true
  validates :session_id, presence: true
end