# frozen_string_literal:true

class AddEventThemeAndAgeRangeToStatisticField < ActiveRecord::Migration[4.2]
  def change
    StatisticField.create!({key:'eventTheme', label:I18n.t('statistics.event_theme'), statistic_index_id: 4, data_type: 'text'})
    StatisticField.create!({key:'ageRange', label:I18n.t('statistics.age_range'), statistic_index_id: 4, data_type: 'text'})
  end
end
