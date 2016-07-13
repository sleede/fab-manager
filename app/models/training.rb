class Training < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one :training_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :training_image, allow_destroy: true

  has_and_belongs_to_many :machines, join_table: :trainings_machines

  has_many :trainings_availabilities
  has_many :availabilities, through: :trainings_availabilities, dependent: :destroy

  has_many :reservations, as: :reservable, dependent: :destroy

  # members who DID the training
  has_many :user_trainings, dependent: :destroy
  has_many :users, through: :user_trainings

  has_many :trainings_pricings, dependent: :destroy

  has_many :credits, as: :creditable, dependent: :destroy
  has_many :plans, through: :credits

  after_create :create_statistic_subtype
  after_create :create_trainings_pricings
  after_update :update_statistic_subtype, if: :name_changed?
  after_destroy :remove_statistic_subtype

  def amount_by_group(group)
    trainings_pricings.where(group_id: group).first
  end

  def create_statistic_subtype
    index = StatisticIndex.where(es_type_key: 'training')
    StatisticSubType.create!({statistic_types: index.first.statistic_types, key: self.slug, label: self.name})
  end

  def update_statistic_subtype
    index = StatisticIndex.where(es_type_key: 'training')
    subtype = StatisticSubType.joins(statistic_type_sub_types: :statistic_type).where(key: self.slug, statistic_types: { statistic_index_id: index.first.id }).first
    subtype.label = self.name
    subtype.save!
  end

  def remove_statistic_subtype
    subtype = StatisticSubType.where(key: self.slug).first
    subtype.destroy!
  end

  def destroyable?
    reservations.empty?
  end

  private
    def create_trainings_pricings
      Group.all.each do |group|
        TrainingsPricing.create(training: self, group: group, amount: 0)
      end
    end
end
