class OpenAPI::CallsCountTracing < ApplicationRecord
  belongs_to :client, foreign_key: :open_api_client_id
  validates :client, :at, presence: true
end
