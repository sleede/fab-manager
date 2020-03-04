# frozen_string_literal: true

# Plan is a generic description of a subscription plan, which can be subscribed by a member to benefit from advantageous prices.
# Subscribers can also get some Credits for some reservable items
class Plan < ActiveRecord::Base
  belongs_to :group

  has_many :credits, dependent: :destroy
  has_many :training_credits, -> { where(creditable_type: 'Training') }, class_name: 'Credit'
  has_many :machine_credits, -> { where(creditable_type: 'Machine') }, class_name: 'Credit'
  has_many :space_credits, -> { where(creditable_type: 'Space') }, class_name: 'Credit'
  has_many :subscriptions
  has_one :plan_image, as: :viewable, dependent: :destroy
  has_one :plan_file, as: :viewable, dependent: :destroy
  has_many :prices, dependent: :destroy

  extend FriendlyId
  friendly_id :base_name, use: :slugged

  accepts_nested_attributes_for :prices
  accepts_nested_attributes_for :plan_file, allow_destroy: true, reject_if: :all_blank

  after_create :create_machines_prices
  after_create :create_spaces_prices
  after_create :create_statistic_type
  after_create :set_name

  validates :amount, :group, :base_name, presence: true
  validates :interval_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :interval_count, numericality: { less_than: 13 }, if: proc { |plan| plan.interval == 'month' }
  validates :interval_count, numericality: { less_than: 53 }, if: proc { |plan| plan.interval == 'week' }
  validates :interval, inclusion: { in: %w[year month week] }
  validates :base_name, :slug, presence: true

  def self.create_for_all_groups(plan_params)
    plans = []
    Group.all_except_admins.each do |group|
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
    Machine.all.each do |machine|
      Price.create(priceable: machine, plan: self, group_id: group_id, amount: 0)
    end
  end

  def create_spaces_prices
    Space.all.each do |space|
      Price.create(priceable: space, plan: self, group_id: group_id, amount: 0)
    end
  end

  def duration
    interval_count.send(interval)
  end

  def human_readable_duration
    i18n_key = "duration.#{interval}"
    I18n.t(i18n_key, count: interval_count).to_s
  end

  def human_readable_name(opts = {})
    result = base_name.to_s
    result += " - #{group.slug}" if opts[:group]
    result + " - #{human_readable_duration}"
  end

  # must be publicly accessible for the migration
  def create_statistic_type
    stat_index = StatisticIndex.where(es_type_key: 'subscription')
    type = StatisticType.find_by(statistic_index_id: stat_index.first.id, key: duration.to_i)
    if type.nil?
      type = StatisticType.create!(
        statistic_index_id: stat_index.first.id,
        key: duration.to_i,
        label: "Durée : #{human_readable_duration}",
        graph: true,
        simple: true
      )
    end
    subtype = create_statistic_subtype
    create_statistic_association(type, subtype)
  end

  private

  def create_statistic_subtype
    StatisticSubType.create!(key: slug, label: name)
  end

  def create_statistic_association(stat_type, stat_subtype)
    if !stat_type.nil? && !stat_subtype.nil?
      StatisticTypeSubType.create!(statistic_type: stat_type, statistic_sub_type: stat_subtype)
    else
      puts 'ERROR: Unable to create the statistics association for the new plan. ' \
           'Possible causes: the type or the subtype were not created successfully.'
    end
  end

  def set_name
    update_columns(name: human_readable_name)
  end
end
