# frozen_string_literal: true

# OpenAPI::Client keeps track of the authorized accesses to the 3-rd party API (aka. OpenAPI)
class OpenAPI::Client < ApplicationRecord
  belongs_to :user, optional: false
  validates :name, presence: true
  validates :token, uniqueness: true
  validates :user_id, presence: true

  before_create :set_initial_token

  def increment_calls_count
    update_column(:calls_count, calls_count + 1)
  end

  def regenerate_token
    update(token: generate_unique_secure_token)
  end

  private

  def set_initial_token
    self.token = generate_unique_secure_token
  end

  def generate_unique_secure_token
    SecureRandom.base58(24)
  end

  def can_perform?(action, resource)
    user.can?(action, resource)
  end
end
