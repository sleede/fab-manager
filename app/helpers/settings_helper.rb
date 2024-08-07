# frozen_string_literal: true

# Helpers methods listing all the settings used in setting.rb
# The following list contains all the settings that can be customized from the Fab-manager's UI.
# A few of them that are system settings, that should not be updated manually (uuid, origin...).

# rubocop:disable Metrics/ModuleLength
module SettingsHelper
  # WARNING: when adding a new key, you may also want to add it in:
  # - config/locales/en.yml#settings
  # - app/frontend/src/javascript/models/setting.ts#SettingName
  # - db/seeds.rb (to set the default value)
  # - app/policies/setting_policy.rb#public_whitelist (if the setting can be read by anyone)
  # - test/fixtures/settings.yml (for backend testing)
  # - test/fixtures/history_values.yml (example value for backend testing)
  # - test/frontend/__fixtures__/settings.ts (example value for frontend testing)
  SETTINGS = %w[
    about_title
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
    machine_reservation_deadline
    training_reservation_deadline
    event_reservation_deadline
    space_reservation_deadline
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
    accounting_payment_transfer_code
    accounting_payment_transfer_label
    accounting_payment_transfer_journal_code
    accounting_payment_check_code
    accounting_payment_check_label
    accounting_payment_check_journal_code
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
    family_account
    child_validation_required
    store_module
    store_withdrawal_instructions
    store_hidden
    advanced_accounting
    external_id
    prevent_invoices_zero
    invoice_VAT-name
    trainings_auto_cancel
    trainings_auto_cancel_threshold
    trainings_auto_cancel_deadline
    trainings_authorization_validity
    trainings_authorization_validity_duration
    trainings_invalidation_rule
    trainings_invalidation_rule_period
    machines_banner_active
    machines_banner_text
    machines_banner_cta_active
    machines_banner_cta_label
    machines_banner_cta_url
    trainings_banner_active
    trainings_banner_text
    trainings_banner_cta_active
    trainings_banner_cta_label
    trainings_banner_cta_url
    events_banner_active
    events_banner_text
    events_banner_cta_active
    events_banner_cta_label
    events_banner_cta_url
    projects_list_member_filter_presence
    projects_list_date_filters_presence
    project_categories_filter_placeholder
    project_categories_wording
    reservation_context_feature
    gender_required
    birthday_required
  ].freeze
end
# rubocop:enable Metrics/ModuleLength
