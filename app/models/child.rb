# frozen_string_literal: true

# Child is a modal for a child of a user
class Child < ApplicationRecord
  belongs_to :user

  validates :first_name, presence: true
  validates :last_name, presence: true
  validate :validate_age

  def validate_age
    errors.add(:birthday, 'You should be over 18 years old.') if birthday.blank? && birthday < 18.years.ago
  end
end
