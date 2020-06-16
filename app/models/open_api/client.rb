# frozen_string_literal: true

# OpenAPI::Client keeps track of the authorized accesses to the 3-rd party API (aka. OpenAPI)
class OpenAPI::Client < ApplicationRecord
  has_many :calls_count_tracings, foreign_key: :open_api_client_id, dependent: :destroy

  validates :name, presence: true
  validates_uniqueness_of :token

  before_create :set_initial_token

  def increment_calls_count
    update_column(:calls_count, calls_count+1)
  end

  def regenerate_token
    update_attributes(token: generate_unique_secure_token)
  end

  private

  def set_initial_token
    self.token = generate_unique_secure_token
  end

  def generate_unique_secure_token
    SecureRandom.base58(24)
  end
end
