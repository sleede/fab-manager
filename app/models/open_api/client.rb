class OpenAPI::Client < ActiveRecord::Base
  has_many :calls_count_tracings, foreign_key: :open_api_client_id, dependent: :destroy
  has_secure_token
  validates :name, presence: true

  def increment_calls_count
    update_column(:calls_count, calls_count+1)
  end
end
