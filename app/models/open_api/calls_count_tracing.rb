class OpenAPI::CallsCountTracing < ApplicationRecord
  belongs_to :projets, foreign_key: :open_api_client_id
  validates :projets, :at, presence: true
end
