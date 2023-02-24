# frozen_string_literal: true

# Training is a course for members to acquire knowledge on a specific matter.
# Trainings are designed to be scheduled periodically through Availabilities.
# A Training can be a prerequisite before members can book a Machine.
class Training < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one :training_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :training_image, allow_destroy: true

  has_many :trainings_machines, dependent: :destroy
  has_many :machines, through: :trainings_machines

  has_many :trainings_availabilities, dependent: :destroy
  has_many :availabilities, through: :trainings_availabilities, dependent: :destroy

  has_many :reservations, as: :reservable, dependent: :destroy

  # members who has validated the trainings
  has_many :statistic_profile_trainings, dependent: :destroy
  has_many :statistic_profiles, through: :statistic_profile_trainings

  has_many :trainings_pricings, dependent: :destroy

  has_many :credits, as: :creditable, dependent: :destroy
  has_many :plans, through: :credits

  has_one :payment_gateway_object, -> { order id: :desc }, inverse_of: :training, as: :item, dependent: :destroy

  has_one :advanced_accounting, as: :accountable, dependent: :destroy
  accepts_nested_attributes_for :advanced_accounting, allow_destroy: true

  has_many :cart_item_training_reservations, class_name: 'CartItem::TrainingReservation', dependent: :destroy, inverse_of: :reservable,
                                             foreign_type: 'reservable_type', as: :reservable

  after_create :create_statistic_subtype
  after_create :create_trainings_pricings
  after_create :update_gateway_product
  after_update :update_gateway_product, if: :saved_change_to_name?
  after_update :update_statistic_subtype, if: :saved_change_to_name?
  after_destroy :remove_statistic_subtype

  def amount_by_group(group)
    trainings_pricings.where(group_id: group).first
  end

  def create_statistic_subtype
    index = StatisticIndex.find_by(es_type_key: 'training')
    StatisticSubType.create!(statistic_types: index.statistic_types, key: slug, label: name)
  end

  def update_statistic_subtype
    index = StatisticIndex.find_by(es_type_key: 'training')
    subtype = StatisticSubType.joins(statistic_type_sub_types: :statistic_type)
                              .find_by!(key: slug, statistic_types: { statistic_index_id: index.id })
    subtype.update(label: name)
  end

  def remove_statistic_subtype
    subtype = StatisticSubType.find_by(key: slug)
    subtype.destroy!
  end

  def destroyable?
    reservations.empty?
  end

  def override_settings?
    Trainings::AutoCancelService.override_settings?(self) ||
      Trainings::InvalidationService.override_settings?(self) ||
      Trainings::AuthorizationService.override_settings?(self)
  end

  private

  def create_trainings_pricings
    Group.find_each do |group|
      TrainingsPricing.create(training: self, group: group, amount: 0)
    end
  end

  def update_gateway_product
    PaymentGatewayService.new.create_or_update_product(Training.name, id)
  end
end
