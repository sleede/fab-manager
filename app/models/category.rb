# frozen_string_literal: true

# Category is a first-level filter, used to categorize Events.
# It is mandatory to choose a Category when creating an event.
class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :events, dependent: :destroy

  after_create :create_statistic_subtype
  after_update :update_statistic_subtype, if: :saved_change_to_name?
  after_destroy :remove_statistic_subtype

  def create_statistic_subtype
    index = StatisticIndex.find_by(es_type_key: 'event')
    StatisticSubType.create!(statistic_types: index.statistic_types, key: slug, label: name)
  end

  def update_statistic_subtype
    index = StatisticIndex.find_by(es_type_key: 'event')
    subtype = StatisticSubType.joins(statistic_type_sub_types: :statistic_type)
                              .find_by(key: previous_changes[:name][0], statistic_types: { statistic_index_id: index.id })
    subtype.label = name
    subtype.save!
  end

  def remove_statistic_subtype
    subtype = StatisticSubType.where(key: slug).first
    subtype.destroy!
  end

  def safe_destroy
    if Category.count > 1 && events.count.zero?
      destroy
    else
      false
    end
  end
end
