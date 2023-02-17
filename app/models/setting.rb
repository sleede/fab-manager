# frozen_string_literal: true

# Setting is a configuration element of the platform. Only administrators are allowed to modify Settings
# For some settings, changing them will involve some callback actions (like rebuilding the stylesheets
# if the theme color Setting has changed).
# A full history of the previous values is kept in database with the date and the author of the change
# after_update callback is handled by SettingService
class Setting < ApplicationRecord
  include SettingsHelper

  has_many :history_values, dependent: :destroy

  # The full list of settings is declared in SettingsHelper
  validates :name, inclusion: { in: SETTINGS }

  def value
    last_value = history_values.order(HistoryValue.arel_table['created_at'].desc).limit(1).first
    last_value&.value
  end

  def value_at(date)
    val = history_values.order(HistoryValue.arel_table['created_at'].desc).where('created_at <= ?', date).limit(1).first
    val&.value
  end

  def first_update
    first_value = history_values.order(HistoryValue.arel_table['created_at'].asc).limit(1).first
    first_value&.created_at
  end

  def first_value
    first_value = history_values.order(HistoryValue.arel_table['created_at'].asc).limit(1).first
    first_value&.value
  end

  def last_update
    last_value = history_values.order(HistoryValue.arel_table['created_at'].desc).limit(1).first
    last_value&.created_at
  end

  def previous_value
    last_two = history_values.order(HistoryValue.arel_table['created_at'].desc).limit(2)
    return nil if last_two.count < 2

    last_two.last&.value
  end

  def previous_update
    last_two = history_values.order(HistoryValue.arel_table['created_at'].desc).limit(2)
    return nil if last_two.count < 2

    last_two.last&.created_at
  end

  # @deprecated, prefer Setting.set() instead
  def value=(val)
    admin = User.admins.first
    save && history_values.create(invoicing_profile: admin.invoicing_profile, value: val)
  end

  # Return the value of the requested setting, if any.
  # @example Setting.get('my_setting') #=> "foo"
  # @param name [String]
  # @return [String,Boolean]
  def self.get(name)
    res = find_by('LOWER(name) = ? ', name.downcase)&.value

    # handle boolean values
    return true if res == 'true'
    return false if res == 'false'

    res
  end

  # Create or update the provided setting with the given value
  # @example Setting.set('my_setting', true)
  # Optionally (but recommended when possible), the user updating the value can be provided as the third parameter
  # Eg.: Setting.set('my_setting', true, User.find_by(slug: 'admin'))
  # @param name [String]
  # @param value [String,Boolean,Numeric,NilClass]
  def self.set(name, value, user = User.admins.first)
    setting = find_or_initialize_by(name: name)
    setting.save && setting.history_values.create(invoicing_profile: user.invoicing_profile, value: value.to_s)
  end

  # Check if the given setting was set
  # @param name [String]
  # @return [Boolean]
  def self.set?(name)
    !find_by(name: name)&.value.nil?
  end
end
