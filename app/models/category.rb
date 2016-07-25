class Category < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :events, dependent: :destroy

  after_create :create_statistic_subtype
  after_update :update_statistic_subtype, if: :name_changed?
  after_destroy :remove_statistic_subtype


  def create_statistic_subtype
    index = StatisticIndex.where(es_type_key: 'event')
    StatisticSubType.create!({statistic_types: index.first.statistic_types, key: self.slug, label: self.name})
  end

  def update_statistic_subtype
    index = StatisticIndex.where(es_type_key: 'event')
    subtype = StatisticSubType.joins(statistic_type_sub_types: :statistic_type).where(key: self.slug, statistic_types: { statistic_index_id: index.first.id }).first
    subtype.label = self.name
    subtype.save!
  end

  def remove_statistic_subtype
    subtype = StatisticSubType.where(key: self.slug).first
    subtype.destroy!
  end

  def safe_destroy
    if Category.count > 1 && self.events.count == 0
      destroy
    else
      false
    end
  end
end
