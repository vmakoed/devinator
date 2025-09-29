class JqlQuery < ApplicationRecord
  belongs_to :session

  validates :query_text, presence: true
  validates :session_id, presence: true
end