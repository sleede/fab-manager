# frozen_string_literal: true

# Group is way to bind users with prices. Different prices can be defined for each plan/reservable, for each group
class Group < ApplicationRecord
  has_many :plans
  has_many :users
  has_many :statistic_profiles
  has_many :trainings_pricings, dependent: :destroy
  has_many :machines_prices, -> { where(priceable_type: 'Machine') }, class_name: 'Price', dependent: :destroy
  has_many :spaces_prices, -> { where(priceable_type: 'Space') }, class_name: 'Price', dependent: :destroy
  has_many :proof_of_identity_types_groups, dependent: :destroy
  has_many :proof_of_identity_types, through: :proof_of_identity_types_groups

  scope :all_except_admins, -> { where.not(slug: 'admins') }

  extend FriendlyId
  friendly_id :name, use: :slugged

  validates :name, :slug, presence: true
  validates :disabled, inclusion: { in: [false, nil] }, if: :group_has_users?

  after_create :create_prices
  after_create :create_statistic_subtype
  after_update :update_statistic_subtype, if: :saved_change_to_name?
  after_update :disable_plans, if: :saved_change_to_disabled?

  def destroyable?
    users.empty? and plans.empty?
  end

  def group_has_users?
    users.count.positive?
  end

  private

  def create_prices
    create_trainings_pricings
    create_machines_prices
    create_spaces_prices
  end

  def create_trainings_pricings
    Training.all.each do |training|
      TrainingsPricing.create(group: self, training: training, amount: 0)
    end
  end

  def create_machines_prices
    Machine.all.each do |machine|
      Price.create(priceable: machine, group: self, amount: 0)
    end
  end

  def create_spaces_prices
    Space.all.each do |space|
      Price.create(priceable: space, group: self, amount: 0)
    end
  end

  def create_statistic_subtype
    user_index = StatisticIndex.find_by(es_type_key: 'user')
    StatisticSubType.create!( statistic_types: user_index.statistic_types, key: slug, label: name)
  end

  def update_statistic_subtype
    user_index = StatisticIndex.find_by(es_type_key: 'user')
    subtype = StatisticSubType.joins(statistic_type_sub_types: :statistic_type)
                              .where(key: slug, statistic_types: { statistic_index_id: user_index.id })
                              .first
    subtype.label = name
    subtype.save!
  end

  def disable_plans
    plans.each do |plan|
      plan.update_attributes(disabled: disabled)
    end
  end
end
