class Plan < ActiveRecord::Base
  belongs_to :group

  has_many :credits, dependent: :destroy
  has_many :training_credits, -> {where(creditable_type: 'Training')}, class_name: 'Credit'
  has_many :machine_credits, -> {where(creditable_type: 'Machine')}, class_name: 'Credit'
  has_many :subscriptions
  has_one :plan_image, as: :viewable, dependent: :destroy
  has_one :plan_file, as: :viewable, dependent: :destroy
  has_many :prices, dependent: :destroy

  extend FriendlyId
  friendly_id :name, use: :slugged

  accepts_nested_attributes_for :prices
  accepts_nested_attributes_for :plan_file, allow_destroy: true, reject_if: :all_blank

  after_update :update_stripe_plan, if: :amount_changed?
  after_create :create_stripe_plan, unless: :skip_create_stripe_plan
  after_create :create_machines_prices
  after_create :create_statistic_type
  after_destroy :delete_stripe_plan

  attr_accessor :skip_create_stripe_plan

  validates :amount, :group, :base_name, presence: true
  validates :interval_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :interval, inclusion: { in: %w(year month) }

  def self.create_for_all_groups(plan_params)
    plans = []
    Group.all.each do |group|
      if plan_params[:type] == 'PartnerPlan'
        plan = PartnerPlan.new(plan_params.except(:group_id, :type))
      else
        plan = Plan.new(plan_params.except(:group_id, :type))
      end
      plan.group = group
      if plan.save
        plans << plan
      else
        plans.each(&:destroy)
        return false
      end
    end
    return plans
  end

  def destroyable?
    subscriptions.empty?
  end

  def create_machines_prices
    Machine.all.each do |machine|
      Price.create(priceable: machine, plan: self, group_id: self.group_id, amount: 0)
    end
  end

  def duration
    interval_count.send(interval)
  end

  def human_readable_duration
    i18n_key = "duration.#{interval}"
    "#{I18n.t(i18n_key, count: interval_count)}"
  end

  def human_readable_name(opts = {})
    result = "#{base_name}"
    result += " - #{group.slug}" if opts[:group]
    result + " - #{human_readable_duration}"
  end

  # must be publicly accessible for the migration
  def create_statistic_type
    stat_index = StatisticIndex.where({es_type_key: 'subscription'})
    type = StatisticType.find_by(statistic_index_id: stat_index.first.id, key: self.duration.to_i)
    if type == nil
      type = StatisticType.create!({statistic_index_id: stat_index.first.id, key: self.duration.to_i, label: 'Durée : '+self.human_readable_duration, graph: true, simple: true})
    end
    subtype = create_statistic_subtype
    create_statistic_association(type, subtype)
  end

  private
  def create_stripe_plan
    stripe_plan = Stripe::Plan.create(
      amount: amount,
      interval: interval,
      interval_count: interval_count,
      name: "#{base_name} - #{group.name} - #{interval}",
      currency: Rails.application.secrets.stripe_currency,
      id: "#{base_name.parameterize}-#{group.slug}-#{interval}-#{DateTime.now.to_s(:number)}"
    )
    update_columns(stp_plan_id: stripe_plan.id, name: stripe_plan.name)
    stripe_plan
  end

  def create_statistic_subtype
    StatisticSubType.create!({key: self.slug, label: self.name})
  end

  def create_statistic_association(stat_type, stat_subtype)
    if stat_type != nil and stat_subtype != nil
      StatisticTypeSubType.create!({statistic_type: stat_type, statistic_sub_type: stat_subtype})
    else
      puts 'ERROR: Unable to create the statistics association for the new plan. '+
           'Possible causes: the type or the subtype were not created successfully.'
    end
  end

  def update_stripe_plan
    old_stripe_plan = Stripe::Plan.retrieve(stp_plan_id)
    old_stripe_plan.delete
    create_stripe_plan
  end

  def delete_stripe_plan
    Stripe::Plan.retrieve(stp_plan_id).delete
  end
end
