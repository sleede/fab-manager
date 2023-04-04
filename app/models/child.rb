# frozen_string_literal: true

# Child is a modal for a child of a user
class Child < ApplicationRecord
  belongs_to :user

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, format: { with: Devise.email_regexp }
  validate :validate_age

  # birthday should less than 18 years ago
  def validate_age
    errors.add(:birthday, I18n.t('.errors.messages.birthday_less_than_18_years_ago')) if birthday.blank? || birthday > 18.years.ago
  end
end
