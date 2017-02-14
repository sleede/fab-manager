class Space < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged

  validates :name, :default_places, presence: true

  has_one :space_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :space_image, allow_destroy: true
  has_many :space_files, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :space_files, allow_destroy: true, reject_if: :all_blank

  has_and_belongs_to_many :projects, join_table: :projects_spaces

  has_many :spaces_availabilities
  has_many :availabilities, through: :spaces_availabilities, dependent: :destroy

  has_many :reservations, as: :reservable, dependent: :destroy

  has_many :prices, as: :priceable, dependent: :destroy
  has_many :credits, as: :creditable, dependent: :destroy

  after_create :create_statistic_subtype
  after_create :create_space_prices
  after_update :update_statistic_subtype, if: :name_changed?
  after_destroy :remove_statistic_subtype


  def create_statistic_subtype
    index = StatisticIndex.find_by(es_type_key: 'space')
    StatisticSubType.create!({statistic_types: index.statistic_types, key: self.slug, label: self.name})
  end

  def update_statistic_subtype
    index = StatisticIndex.find_by(es_type_key: 'space')
    subtype = StatisticSubType.joins(statistic_type_sub_types: :statistic_type).find_by(key: self.slug, statistic_types: { statistic_index_id: index.id })
    subtype.label = self.name
    subtype.save!
  end

  def remove_statistic_subtype
    subtype = StatisticSubType.find_by(key: self.slug)
    subtype.destroy!
  end

  def create_space_prices
    Group.all.each do |group|
      Price.create(priceable: self, group: group, amount: 0)
    end

    Plan.all.includes(:group).each do |plan|
      Price.create(group: plan.group, plan: plan, priceable: self, amount: 0)
    end
  end

  def destroyable?
    reservations.empty?
  end
end
