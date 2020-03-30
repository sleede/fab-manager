# frozen_string_literal: true

# Tag is a way to restrict an Availability for reservation to users with the same Tag.
class Tag < ApplicationRecord
  has_many :user_tags, dependent: :destroy
  has_many :users, through: :user_tags

  has_many :availability_tags, dependent: :destroy
  has_many :availabilities, through: :availability_tags
end
