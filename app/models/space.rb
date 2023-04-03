# frozen_string_literal: true

# Space is a reservable item that can be booked by multiple people on the same Slot.
# It represents a physical place, in the Fablab, like a meeting room where multiple people will be able to work at
# the same time.
class Space < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  validates :name, :default_places, presence: true

  has_one :space_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :space_image, allow_destroy: true
  has_many :space_files, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :space_files, allow_destroy: true, reject_if: :all_blank

  has_many :projects_spaces, dependent: :destroy
  has_many :projects, through: :projects_spaces

  has_many :spaces_availabilities, dependent: :destroy
  has_many :availabilities, through: :spaces_availabilities, dependent: :destroy

  has_many :reservations, as: :reservable, dependent: :destroy

  has_many :prices, as: :priceable, dependent: :destroy
  has_many :prepaid_packs, as: :priceable, dependent: :destroy
  has_many :credits, as: :creditable, dependent: :destroy

  has_one :payment_gateway_object, -> { order id: :desc }, inverse_of: :space, as: :item, dependent: :destroy

  has_one :advanced_accounting, as: :accountable, dependent: :destroy
  accepts_nested_attributes_for :advanced_accounting, allow_destroy: true

  has_many :cart_item_space_reservations, class_name: 'CartItem::SpaceReservation', dependent: :destroy, inverse_of: :reservable,
                                          foreign_type: 'reservable_type', as: :reservable

  after_create :create_statistic_subtype
  after_create :create_space_prices
  after_create :update_gateway_product
  after_update :update_gateway_product, if: :saved_change_to_name?
  after_update :update_statistic_subtype, if: :saved_change_to_name?
  after_destroy :remove_statistic_subtype

  def create_statistic_subtype
    index = StatisticIndex.find_by(es_type_key: 'space')
    StatisticSubType.create!({ statistic_types: index.statistic_types, key: slug, label: name })
  end

  def update_statistic_subtype
    index = StatisticIndex.find_by(es_type_key: 'space')
    subtype = StatisticSubType.joins(statistic_type_sub_types: :statistic_type)
                              .find_by(key: slug, statistic_types: { statistic_index_id: index.id })
    subtype.update(label: name)
  end

  def remove_statistic_subtype
    subtype = StatisticSubType.find_by(key: slug)
    subtype.destroy!
  end

  def create_space_prices
    Group.find_each do |group|
      Price.create(priceable: self, group: group, amount: 0)
    end

    Plan.includes(:group).find_each do |plan|
      Price.create(group: plan.group, plan: plan, priceable: self, amount: 0)
    end
  end

  def destroyable?
    reservations.empty?
  end

  def soft_destroy!
    update(deleted_at: Time.current)
  end

  private

  def update_gateway_product
    PaymentGatewayService.new.create_or_update_product(Space.name, id)
  end
end
