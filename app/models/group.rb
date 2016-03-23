class Group < ActiveRecord::Base
  has_many :plans
  has_many :users
  has_many :trainings_pricings, dependent: :destroy
  has_many :machines_prices, ->{ where(priceable_type: 'Machine') }, class_name: 'Price', dependent: :destroy

  extend FriendlyId
  friendly_id :name, use: :slugged

  validates :name, :slug, presence: true

  after_create :create_prices
  after_create :create_statistic_subtype
  after_update :update_statistic_subtype, if: :name_changed?

  def destroyable?
    users.empty? and plans.empty?
  end

  private
    def create_prices
      create_trainings_pricings
      create_machines_prices
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

  def create_statistic_subtype
    user_index = StatisticIndex.find_by(es_type_key: 'user')
    StatisticSubType.create!({statistic_types: user_index.statistic_types, key: self.slug, label: self.name})
  end

  def update_statistic_subtype
    user_index = StatisticIndex.find_by(es_type_key: 'user')
    subtype = StatisticSubType.joins(statistic_type_sub_types: :statistic_type).where(key: self.slug, statistic_types: { statistic_index_id: user_index.id }).first
    subtype.label = self.name
    subtype.save!
  end
end
