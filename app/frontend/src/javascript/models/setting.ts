import { HistoryValue } from './history-value';
import { TDateISO } from '../typings/date-iso';

export const homePageSettings = [
  'twitter_name',
  'home_blogpost',
  'home_content',
  'home_css',
  'upcoming_events_shown'
] as const;

export const privacyPolicySettings = [
  'privacy_draft',
  'privacy_body',
  'privacy_dpo'
] as const;

export const aboutPageSettings = [
  'about_title',
  'about_body',
  'about_contacts',
  'link_name'
] as const;

export const socialNetworksSettings = [
  'facebook',
  'twitter',
  'viadeo',
  'linkedin',
  'instagram',
  'youtube',
  'vimeo',
  'dailymotion',
  'github',
  'echosciences',
  'pinterest',
  'lastfm',
  'flickr'
] as const;

export const messagesSettings = [
  'machine_explications_alert',
  'training_explications_alert',
  'training_information_message',
  'subscription_explications_alert',
  'event_explications_alert',
  'space_explications_alert'
] as const;

export const invoicesSettings = [
  'invoice_logo',
  'invoice_reference',
  'invoice_code-active',
  'invoice_code-value',
  'invoice_order-nb',
  'invoice_VAT-active',
  'invoice_VAT-rate',
  'invoice_VAT-rate_Machine',
  'invoice_VAT-rate_Training',
  'invoice_VAT-rate_Space',
  'invoice_VAT-rate_Event',
  'invoice_VAT-rate_Subscription',
  'invoice_VAT-rate_Product',
  'invoice_text',
  'invoice_legals',
  'invoice_prefix',
  'payment_schedule_prefix'
] as const;

export const bookingSettings = [
  'booking_window_start',
  'booking_window_end',
  'booking_move_enable',
  'booking_move_delay',
  'booking_cancel_enable',
  'booking_cancel_delay',
  'reminder_enable',
  'reminder_delay',
  'visibility_yearly',
  'visibility_others',
  'reservation_deadline',
  'display_name_enable',
  'book_overlapping_slots',
  'slot_duration',
  'overlapping_categories'
] as const;

export const themeSettings = [
  'main_color',
  'secondary_color'
] as const;

export const titleSettings = [
  'fablab_name',
  'name_genre'
] as const;

export const accountingSettings = [
  'accounting_journal_code',
  'accounting_card_client_code',
  'accounting_card_client_label',
  'accounting_wallet_client_code',
  'accounting_wallet_client_label',
  'accounting_other_client_code',
  'accounting_other_client_label',
  'accounting_wallet_code',
  'accounting_wallet_label',
  'accounting_VAT_code',
  'accounting_VAT_label',
  'accounting_subscription_code',
  'accounting_subscription_label',
  'accounting_Machine_code',
  'accounting_Machine_label',
  'accounting_Training_code',
  'accounting_Training_label',
  'accounting_Event_code',
  'accounting_Event_label',
  'accounting_Space_code',
  'accounting_Space_label',
  'accounting_Pack_code',
  'accounting_Pack_label',
  'accounting_Product_code',
  'accounting_Product_label',
  'accounting_Error_code',
  'accounting_Error_label',
  'advanced_accounting'
] as const;

export const modulesSettings = [
  'spaces_module',
  'plans_module',
  'wallet_module',
  'statistics_module',
  'trainings_module',
  'machines_module',
  'online_payment_module',
  'public_agenda_module',
  'invoicing_module',
  'store_module'
] as const;

export const stripeSettings = [
  'stripe_public_key',
  'stripe_secret_key',
  'stripe_currency'
] as const;

export const payzenSettings = [
  'payzen_username',
  'payzen_password',
  'payzen_endpoint',
  'payzen_public_key',
  'payzen_hmac',
  'payzen_currency'
] as const;

export const openLabSettings = [
  'openlab_app_id',
  'openlab_app_secret',
  'openlab_default'
] as const;

export const accountSettings = [
  'phone_required',
  'confirmation_required',
  'address_required',
  'user_change_group',
  'user_validation_required',
  'user_validation_required_list'
] as const;

export const analyticsSettings = [
  'tracking_id',
  'facebook_app_id',
  'twitter_analytics'
] as const;

export const fabHubSettings = [
  'hub_last_version',
  'hub_public_key',
  'fab_analytics',
  'origin',
  'uuid'
] as const;

export const projectsSettings = [
  'allowed_cad_extensions',
  'allowed_cad_mime_types',
  'disqus_shortname'
] as const;

export const prepaidPacksSettings = [
  'renew_pack_threshold',
  'pack_only_for_subscription'
] as const;

export const registrationSettings = [
  'public_registrations',
  'recaptcha_site_key',
  'recaptcha_secret_key'
] as const;

export const adminSettings = [
  'feature_tour_display',
  'show_username_in_admin_list'
] as const;

export const pricingSettings = [
  'extended_prices_in_same_day'
] as const;

export const poymentSettings = [
  'payment_gateway'
] as const;

export const displaySettings = [
  'machines_sort_by',
  'events_in_calendar',
  'email_from'
] as const;

export const storeSettings = [
  'store_withdrawal_instructions',
  'store_hidden'
] as const;

export const allSettings = [
  ...homePageSettings,
  ...privacyPolicySettings,
  ...aboutPageSettings,
  ...socialNetworksSettings,
  ...messagesSettings,
  ...invoicesSettings,
  ...bookingSettings,
  ...themeSettings,
  ...titleSettings,
  ...accountingSettings,
  ...modulesSettings,
  ...stripeSettings,
  ...payzenSettings,
  ...openLabSettings,
  ...accountSettings,
  ...analyticsSettings,
  ...fabHubSettings,
  ...projectsSettings,
  ...prepaidPacksSettings,
  ...registrationSettings,
  ...adminSettings,
  ...pricingSettings,
  ...poymentSettings,
  ...displaySettings,
  ...storeSettings
] as const;

export type SettingName = typeof allSettings[number];

export type SettingValue = string|boolean|number;

export interface Setting {
  name: SettingName,
  localized?: string,
  value: string,
  last_update?: TDateISO,
  history?: Array<HistoryValue>
}

export interface SettingError {
  error: string,
  id: number,
  name: SettingName
}

export interface SettingBulkResult {
  status: boolean,
  value?: string,
  error?: string,
  localized?: string,
}

export type SettingBulkArray = Array<{ name: SettingName, value: SettingValue }>;
