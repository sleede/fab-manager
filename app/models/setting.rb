class Setting < ActiveRecord::Base
  has_many :history_values
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
                             invoice_text
                             invoice_legals
                             booking_window_start
                             booking_window_end
                             booking_slot_duration
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
                             display_name_enable
                             machines_sort_by
                             accounting_journal_code
                             accounting_card_client_code
                             accounting_card_client_label
                             accounting_wallet_client_code
                             accounting_wallet_client_label
                             accounting_other_client_code
                             accounting_other_client_label
                             accounting_wallet_code
                             accounting_wallet_label
                             accounting_VAT_code
                             accounting_VAT_label
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
                             hub_last_version
                             hub_public_key
                             fab_analytics] }

  after_update :update_stylesheet, :notify_privacy_policy_changed if :value_changed?

  def update_stylesheet
    Stylesheet.first&.rebuild! if %w[main_color secondary_color].include? name
  end

  def notify_privacy_policy_changed
    return unless name == 'privacy_body'

    NotifyPrivacyUpdateWorker.perform_async(id)
  end

  def value
    last_value = history_values.order(HistoryValue.arel_table['created_at'].desc).first
    last_value&.value
  end

  def last_update
    last_value = history_values.order(HistoryValue.arel_table['created_at'].desc).first
    last_value&.created_at
  end

  def value=(val)
    admin = User.admins.first
    save && history_values.create(invoicing_profile: admin.invoicing_profile, value: val)
  end
end
