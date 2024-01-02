# frozen_string_literal: true

# Plan is a generic description of a subscription plan, which can be subscribed by a member to benefit from advantageous prices.
# Subscribers can also get some Credits for some reservable items
class Plan < ApplicationRecord
  belongs_to :group
  belongs_to :plan_category

  has_many :credits, dependent: :destroy
  has_many :training_credits, -> { where(creditable_type: 'Training') }, class_name: 'Credit', dependent: :destroy, inverse_of: :plan
  has_many :machine_credits, -> { where(creditable_type: 'Machine') }, class_name: 'Credit', dependent: :destroy, inverse_of: :plan
  has_many :space_credits, -> { where(creditable_type: 'Space') }, class_name: 'Credit', dependent: :destroy, inverse_of: :plan
  has_many :subscriptions, dependent: :nullify
  has_one :plan_file, as: :viewable, dependent: :destroy
  has_many :prices, dependent: :destroy
  has_one :payment_gateway_object, -> { order id: :desc }, inverse_of: :plan, as: :item, dependent: :destroy

  has_many :cart_item_machine_reservations, class_name: 'CartItem::MachineReservation', dependent: :destroy
  has_many :cart_item_space_reservations, class_name: 'CartItem::SpaceReservation', dependent: :destroy
  has_many :cart_item_training_reservations, class_name: 'CartItem::TrainingReservation', dependent: :destroy
  has_many :cart_item_subscriptions, class_name: 'CartItem::Subscription', dependent: :destroy
  has_many :cart_item_payment_schedules, class_name: 'CartItem::PaymentSchedule', dependent: :destroy

  has_many :plan_limitations, dependent: :destroy
  accepts_nested_attributes_for :plan_limitations, allow_destroy: true

  extend FriendlyId
  friendly_id :base_name, use: :slugged

  accepts_nested_attributes_for :prices
  accepts_nested_attributes_for :plan_file, allow_destroy: true, reject_if: :all_blank

  has_one :advanced_accounting, as: :accountable, dependent: :destroy
  accepts_nested_attributes_for :advanced_accounting, allow_destroy: true

  after_create :create_machines_prices
  after_create :create_spaces_prices
  after_create :set_name
  after_create :create_statistic_type
  after_create :update_gateway_product
  after_update :update_gateway_product, if: :saved_change_to_base_name?

  validates :amount, :group, :base_name, presence: true
  validates :interval_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :interval_count, numericality: { less_than: 13 }, if: proc { |plan| plan.interval == 'month' }
  validates :interval_count, numericality: { less_than: 53 }, if: proc { |plan| plan.interval == 'week' }
  validates :interval, inclusion: { in: %w[year month week] }
  validates :base_name, :slug, presence: true

  def self.create_for_all_groups(plan_params)
    plans = []
    Group.where(disabled: [nil, false]).find_each do |group|
      plan = if plan_params[:type] == 'PartnerPlan'
               PartnerPlan.new(plan_params.except(:group_id, :type))
             else
               Plan.new(plan_params.except(:group_id, :type))
             end
      plan.group = group
      if plan.save
        plans << plan
      else
        plans.each(&:destroy)
        return false
      end
    end
    plans
  end

  def destroyable?
    subscriptions.empty?
  end

  def create_machines_prices
    Machine.all.find_each do |machine|
      default_price = Price.find_by(priceable: machine, plan: nil, group_id: group_id)&.amount || 0
      Price.create(priceable: machine, plan: self, group_id: group_id, amount: default_price)
    end
  end

  def create_spaces_prices
    Space.all.find_each do |space|
      default_price = Price.find_by(priceable: space, plan: nil, group_id: group_id)&.amount || 0
      Price.create(priceable: space, plan: self, group_id: group_id, amount: default_price)
    end
  end

  def duration
    interval_count.send(interval)
  end

  def human_readable_duration
    i18n_key = "duration.#{interval}"
    I18n.t(i18n_key, **{ count: interval_count }).to_s
  end

  def human_readable_name(opts = {})
    result = base_name.to_s
    result += " - #{group.slug}" if opts[:group]
    result + " - #{human_readable_duration}"
  end

  # must be publicly accessible for the migration
  def create_statistic_type
    stat_index = StatisticIndex.find_by(es_type_key: 'subscription')
    type = find_statistic_type
    if type.nil?
      type = StatisticType.create!(
        statistic_index_id: stat_index.id,
        key: duration.to_i,
        label: "#{I18n.t('statistics.duration')} : #{human_readable_duration}",
        graph: true,
        simple: true
      )
    end
    subtype = create_statistic_subtype
    create_statistic_association(type, subtype)
  end

  def find_statistic_type
    stat_index = StatisticIndex.find_by(es_type_key: 'subscription')
    type = StatisticType.find_by(statistic_index_id: stat_index.id, key: duration.to_i)
    return type if type

    StatisticType.where(statistic_index_id: stat_index.id).where('label LIKE ?', "%#{human_readable_duration}%").first
  end

  private

  def create_statistic_subtype
    StatisticSubType.create!(key: slug, label: name)
  end

  def create_statistic_association(stat_type, stat_subtype)
    if !stat_type.nil? && !stat_subtype.nil?
      StatisticTypeSubType.create!(statistic_type: stat_type, statistic_sub_type: stat_subtype)
    else
      Rails.logger.error 'Unable to create the statistics association for the new plan. ' \
                         'Possible causes: the type or the subtype were not created successfully.'
    end
  end

  def set_name
    update_columns(name: human_readable_name)  # rubocop:disable Rails/SkipsModelValidations
  end

  def update_gateway_product
    PaymentGatewayService.new.create_or_update_product(Plan.name, id)
  end
end
