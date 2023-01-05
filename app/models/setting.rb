# frozen_string_literal: true

# Setting is a configuration element of the platform. Only administrators are allowed to modify Settings
# For some settings, changing them will involve some callback actions (like rebuilding the stylesheets
# if the theme color Setting has changed).
# A full history of the previous values is kept in database with the date and the author of the change
# after_update callback is handled by SettingService
class Setting < ApplicationRecord
  has_many :history_values, dependent: :destroy
  # The following list contains all the settings that can be customized from the Fab-manager's UI.
  # A few of them that are system settings, that should not be updated manually (uuid, origin...).
  validates :name, inclusion:
                    { in: %w[about_title
                             about_body
                             about_contacts
                             privacy_draft
                             privacy_body
                             privacy_dpo
                             twitter_name
                             home_blogpost
                             machine_explications_alert
                             training_explications_alert
                             training_information_message
                             subscription_explications_alert
                             invoice_logo
                             invoice_reference
                             invoice_code-active
                             invoice_code-value
                             invoice_order-nb
                             invoice_VAT-active
                             invoice_VAT-rate
                             invoice_VAT-rate_Machine
                             invoice_VAT-rate_Training
                             invoice_VAT-rate_Space
                             invoice_VAT-rate_Event
                             invoice_VAT-rate_Subscription
                             invoice_VAT-rate_Product
                             invoice_text
                             invoice_legals
                             booking_window_start
                             booking_window_end
                             booking_move_enable
                             booking_move_delay
                             booking_cancel_enable
                             booking_cancel_delay
                             main_color
                             secondary_color
                             fablab_name
                             name_genre
                             reminder_enable
                             reminder_delay
                             event_explications_alert
                             space_explications_alert
                             visibility_yearly
                             visibility_others
                             reservation_deadline
                             display_name_enable
                             machines_sort_by
                             accounting_sales_journal_code
                             accounting_payment_card_code
                             accounting_payment_card_label
                             accounting_payment_card_journal_code
                             accounting_payment_wallet_code
                             accounting_payment_wallet_label
                             accounting_payment_wallet_journal_code
                             accounting_payment_other_code
                             accounting_payment_other_label
                             accounting_payment_other_journal_code
                             accounting_wallet_code
                             accounting_wallet_label
                             accounting_wallet_journal_code
                             accounting_VAT_code
                             accounting_VAT_label
                             accounting_VAT_journal_code
                             accounting_subscription_code
                             accounting_subscription_label
                             accounting_Machine_code
                             accounting_Machine_label
                             accounting_Training_code
                             accounting_Training_label
                             accounting_Event_code
                             accounting_Event_label
                             accounting_Space_code
                             accounting_Space_label
                             accounting_Product_code
                             accounting_Product_label
                             hub_last_version
                             hub_public_key
                             fab_analytics
                             link_name
                             home_content
                             home_css
                             origin
                             uuid
                             phone_required
                             tracking_id
                             book_overlapping_slots
                             slot_duration
                             events_in_calendar
                             spaces_module
                             plans_module
                             invoicing_module
                             facebook_app_id
                             twitter_analytics
                             recaptcha_site_key
                             recaptcha_secret_key
                             feature_tour_display
                             email_from
                             disqus_shortname
                             allowed_cad_extensions
                             allowed_cad_mime_types
                             openlab_app_id
                             openlab_app_secret
                             openlab_default
                             online_payment_module
                             stripe_public_key
                             stripe_secret_key
                             stripe_currency
                             invoice_prefix
                             confirmation_required
                             wallet_module
                             statistics_module
                             upcoming_events_shown
                             payment_schedule_prefix
                             trainings_module
                             address_required
                             accounting_Error_code
                             accounting_Error_label
                             payment_gateway
                             payzen_username
                             payzen_password
                             payzen_endpoint
                             payzen_public_key
                             payzen_hmac
                             payzen_currency
                             public_agenda_module
                             renew_pack_threshold
                             pack_only_for_subscription
                             overlapping_categories
                             extended_prices_in_same_day
                             public_registrations
                             accounting_Pack_code
                             accounting_Pack_label
                             facebook
                             twitter
                             viadeo
                             linkedin
                             instagram
                             youtube
                             vimeo
                             dailymotion
                             github
                             echosciences
                             pinterest
                             lastfm
                             flickr
                             machines_module
                             user_change_group
                             user_validation_required
                             user_validation_required_list
                             show_username_in_admin_list
                             store_module
                             store_withdrawal_instructions
                             store_hidden
                             advanced_accounting
                             external_id
                             prevent_invoices_zero
                             invoice_VAT-name] }
  # WARNING: when adding a new key, you may also want to add it in:
  # - config/locales/en.yml#settings
  # - app/frontend/src/javascript/models/setting.ts#SettingName
  # - db/seeds.rb (to set the default value)
  # - app/policies/setting_policy.rb#public_whitelist (if the setting can be read by anyone)
  # - test/fixtures/settings.yml (for backend testing)
  # - test/fixtures/history_values.yml (example value for backend testing)
  # - test/frontend/__fixtures__/settings.ts (example value for frontend testing)

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

  def previous_update
    previous_value = history_values.order(HistoryValue.arel_table['created_at'].desc).limit(2).last
    previous_value&.created_at
  end

  # @deprecated, prefer Setting.set() instead
  def value=(val)
    admin = User.admins.first
    save && history_values.create(invoicing_profile: admin.invoicing_profile, value: val)
  end

  ##
  # Return the value of the requested setting, if any.
  # Usage: Setting.get('my_setting')
  # @return {String|Boolean}
  ##
  def self.get(name)
    res = find_by('LOWER(name) = ? ', name.downcase)&.value

    # handle boolean values
    return true if res == 'true'
    return false if res == 'false'

    res
  end

  ##
  # Create or update the provided setting with the given value
  # Usage: Setting.set('my_setting', true)
  # Optionally (but recommended when possible), the user updating the value can be provided as the third parameter
  # Eg.: Setting.set('my_setting', true, User.find_by(slug: 'admin'))
  ##
  def self.set(name, value, user = User.admins.first)
    setting = find_or_initialize_by(name: name)
    setting.save && setting.history_values.create(invoicing_profile: user.invoicing_profile, value: value.to_s)
  end

  ##
  # Check if the given setting was set
  ##
  def self.set?(name)
    !find_by(name: name)&.value.nil?
  end
end
