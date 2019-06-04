# frozen_string_literal: true

# This table will save the user's profile data needed for statistical purposes.
# GDPR requires that an user can delete his account at any time but we need to keep the statistics original data to being able to
# rebuild them at any time.
# The data will be kept even if the user is deleted, but it will be unlinked from the user's account (ie. anonymized)
class StatisticProfile < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  # relations to reservations, trainings, subscriptions
  has_many :subscriptions, dependent: :destroy
  accepts_nested_attributes_for :subscriptions, allow_destroy: false

  has_many :reservations, dependent: :destroy
  accepts_nested_attributes_for :reservations, allow_destroy: false

  def str_gender
    gender ? 'male' : 'female'
  end

  def age
    if birthday.present?
      now = Time.now.utc.to_date
      (now - birthday).to_f / 365.2425
    else
      ''
    end
  end

end
