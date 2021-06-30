# frozen_string_literal: true

AVG_DAYS_PER_YEAR = 365.2425

# This table will save the user's profile data needed for statistical purposes.
# GDPR requires that an user can delete his account at any time but we need to keep the statistics original data to being able to
# rebuild them at any time.
# The data will be kept even if the user is deleted, but it will be unlinked from the user's account (ie. anonymized)
class StatisticProfile < ApplicationRecord
  belongs_to :user
  belongs_to :group
  belongs_to :role

  has_many :subscriptions, dependent: :destroy
  accepts_nested_attributes_for :subscriptions, allow_destroy: false

  has_many :reservations, dependent: :destroy
  accepts_nested_attributes_for :reservations, allow_destroy: false

  # bought packs
  has_many :statistic_profile_prepaid_packs, dependent: :destroy
  has_many :prepaid_packs, through: :statistic_profile_prepaid_packs

  # Trainings that were validated by an admin
  has_many :statistic_profile_trainings, dependent: :destroy
  has_many :trainings, through: :statistic_profile_trainings

  # Projects that the current user is the author
  has_many :my_projects, foreign_key: :author_statistic_profile_id, class_name: 'Project', dependent: :destroy

  def str_gender
    gender ? 'male' : 'female'
  end

  def age
    if birthday.present?
      now = DateTime.current.utc.to_date
      (now - birthday).to_f / AVG_DAYS_PER_YEAR
    else
      ''
    end
  end
end
