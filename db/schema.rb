# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[6.1].define(version: 2023_03_15_095054) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "abuses", id: :serial, force: :cascade do |t|
    t.string "signaled_type"
    t.integer "signaled_id"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["signaled_type", "signaled_id"], name: "index_abuses_on_signaled_type_and_signaled_id"
  end

  create_table "accounting_lines", force: :cascade do |t|
    t.string "line_type"
    t.string "journal_code"
    t.datetime "date"
    t.string "account_code"
    t.string "account_label"
    t.string "analytical_code"
    t.bigint "invoice_id"
    t.bigint "invoicing_profile_id"
    t.integer "debit"
    t.integer "credit"
    t.string "currency"
    t.string "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_accounting_lines_on_invoice_id"
    t.index ["invoicing_profile_id"], name: "index_accounting_lines_on_invoicing_profile_id"
  end

  create_table "accounting_periods", id: :serial, force: :cascade do |t|
    t.date "start_at"
    t.date "end_at"
    t.datetime "closed_at"
    t.integer "closed_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "period_total"
    t.integer "perpetual_total"
    t.string "footprint"
  end

  create_table "addresses", id: :serial, force: :cascade do |t|
    t.string "address"
    t.string "street_number"
    t.string "route"
    t.string "locality"
    t.string "country"
    t.string "postal_code"
    t.string "placeable_type"
    t.integer "placeable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "advanced_accountings", force: :cascade do |t|
    t.string "code"
    t.string "analytical_section"
    t.string "accountable_type"
    t.bigint "accountable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accountable_type", "accountable_id"], name: "index_advanced_accountings_on_accountable"
  end

  create_table "age_ranges", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["slug"], name: "index_age_ranges_on_slug", unique: true
  end

  create_table "assets", id: :serial, force: :cascade do |t|
    t.string "viewable_type"
    t.integer "viewable_id"
    t.string "attachment"
    t.string "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_main"
  end

  create_table "auth_provider_mappings", id: :serial, force: :cascade do |t|
    t.string "local_field"
    t.string "api_field"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "local_model"
    t.string "api_endpoint"
    t.string "api_data_type"
    t.jsonb "transformation"
    t.bigint "auth_provider_id"
    t.index ["auth_provider_id"], name: "index_auth_provider_mappings_on_auth_provider_id"
  end

  create_table "auth_providers", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "providable_type"
    t.integer "providable_id"
    t.index ["name"], name: "index_auth_providers_on_name", unique: true
  end

  create_table "availabilities", id: :serial, force: :cascade do |t|
    t.datetime "start_at"
    t.datetime "end_at"
    t.string "available_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "nb_total_places"
    t.boolean "destroying", default: false
    t.boolean "lock", default: false
    t.boolean "is_recurrent"
    t.integer "occurrence_id"
    t.string "period"
    t.integer "nb_periods"
    t.datetime "end_date"
    t.integer "slot_duration"
  end

  create_table "availability_tags", id: :serial, force: :cascade do |t|
    t.integer "availability_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["availability_id"], name: "index_availability_tags_on_availability_id"
    t.index ["tag_id"], name: "index_availability_tags_on_tag_id"
  end

  create_table "cart_item_coupons", force: :cascade do |t|
    t.bigint "coupon_id"
    t.bigint "customer_profile_id"
    t.bigint "operator_profile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coupon_id"], name: "index_cart_item_coupons_on_coupon_id"
    t.index ["customer_profile_id"], name: "index_cart_item_coupons_on_customer_profile_id"
    t.index ["operator_profile_id"], name: "index_cart_item_coupons_on_operator_profile_id"
  end

  create_table "cart_item_event_reservation_tickets", force: :cascade do |t|
    t.integer "booked"
    t.bigint "event_price_category_id"
    t.bigint "cart_item_event_reservation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_item_event_reservation_id"], name: "index_cart_item_tickets_on_cart_item_event_reservation"
    t.index ["event_price_category_id"], name: "index_cart_item_tickets_on_event_price_category"
  end

  create_table "cart_item_event_reservations", force: :cascade do |t|
    t.integer "normal_tickets"
    t.bigint "event_id"
    t.bigint "operator_profile_id"
    t.bigint "customer_profile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_profile_id"], name: "index_cart_item_event_reservations_on_customer_profile_id"
    t.index ["event_id"], name: "index_cart_item_event_reservations_on_event_id"
    t.index ["operator_profile_id"], name: "index_cart_item_event_reservations_on_operator_profile_id"
  end

  create_table "cart_item_free_extensions", force: :cascade do |t|
    t.bigint "subscription_id"
    t.datetime "new_expiration_date"
    t.bigint "customer_profile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_profile_id"], name: "index_cart_item_free_extensions_on_customer_profile_id"
    t.index ["subscription_id"], name: "index_cart_item_free_extensions_on_subscription_id"
  end

  create_table "cart_item_payment_schedules", force: :cascade do |t|
    t.bigint "plan_id"
    t.bigint "coupon_id"
    t.boolean "requested"
    t.datetime "start_at"
    t.bigint "customer_profile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coupon_id"], name: "index_cart_item_payment_schedules_on_coupon_id"
    t.index ["customer_profile_id"], name: "index_cart_item_payment_schedules_on_customer_profile_id"
    t.index ["plan_id"], name: "index_cart_item_payment_schedules_on_plan_id"
  end

  create_table "cart_item_prepaid_packs", force: :cascade do |t|
    t.bigint "prepaid_pack_id"
    t.bigint "customer_profile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_profile_id"], name: "index_cart_item_prepaid_packs_on_customer_profile_id"
    t.index ["prepaid_pack_id"], name: "index_cart_item_prepaid_packs_on_prepaid_pack_id"
  end

  create_table "cart_item_reservation_slots", force: :cascade do |t|
    t.string "cart_item_type"
    t.bigint "cart_item_id"
    t.bigint "slot_id"
    t.bigint "slots_reservation_id"
    t.boolean "offered", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_item_type", "cart_item_id"], name: "index_cart_item_slots_on_cart_item"
    t.index ["slot_id"], name: "index_cart_item_reservation_slots_on_slot_id"
    t.index ["slots_reservation_id"], name: "index_cart_item_reservation_slots_on_slots_reservation_id"
  end

  create_table "cart_item_reservations", force: :cascade do |t|
    t.string "reservable_type"
    t.bigint "reservable_id"
    t.bigint "plan_id"
    t.boolean "new_subscription"
    t.bigint "customer_profile_id"
    t.bigint "operator_profile_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_profile_id"], name: "index_cart_item_reservations_on_customer_profile_id"
    t.index ["operator_profile_id"], name: "index_cart_item_reservations_on_operator_profile_id"
    t.index ["plan_id"], name: "index_cart_item_reservations_on_plan_id"
    t.index ["reservable_type", "reservable_id"], name: "index_cart_item_reservations_on_reservable"
  end

  create_table "cart_item_subscriptions", force: :cascade do |t|
    t.bigint "plan_id"
    t.datetime "start_at"
    t.bigint "customer_profile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_profile_id"], name: "index_cart_item_subscriptions_on_customer_profile_id"
    t.index ["plan_id"], name: "index_cart_item_subscriptions_on_plan_id"
  end

  create_table "categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "components", id: :serial, force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "coupons", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.integer "percent_off"
    t.datetime "valid_until"
    t.integer "max_usages"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "validity_per_user"
    t.integer "amount_off"
    t.index ["code"], name: "index_coupons_on_code", unique: true
  end

  create_table "credits", id: :serial, force: :cascade do |t|
    t.string "creditable_type"
    t.integer "creditable_id"
    t.integer "plan_id"
    t.integer "hours"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["plan_id", "creditable_id", "creditable_type"], name: "index_credits_on_plan_id_and_creditable_id_and_creditable_type", unique: true
    t.index ["plan_id"], name: "index_credits_on_plan_id"
  end

  create_table "custom_assets", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "database_providers", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "event_price_categories", id: :serial, force: :cascade do |t|
    t.integer "event_id"
    t.integer "price_category_id"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_price_categories_on_event_id"
    t.index ["price_category_id"], name: "index_event_price_categories_on_price_category_id"
  end

  create_table "event_themes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["slug"], name: "index_event_themes_on_slug", unique: true
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "availability_id"
    t.integer "amount"
    t.integer "nb_total_places"
    t.integer "nb_free_places"
    t.integer "recurrence_id"
    t.integer "age_range_id"
    t.integer "category_id"
    t.datetime "deleted_at"
    t.index ["availability_id"], name: "index_events_on_availability_id"
    t.index ["category_id"], name: "index_events_on_category_id"
    t.index ["deleted_at"], name: "index_events_on_deleted_at"
    t.index ["recurrence_id"], name: "index_events_on_recurrence_id"
  end

  create_table "events_event_themes", id: :serial, force: :cascade do |t|
    t.integer "event_id"
    t.integer "event_theme_id"
    t.index ["event_id"], name: "index_events_event_themes_on_event_id"
    t.index ["event_theme_id"], name: "index_events_event_themes_on_event_theme_id"
  end

  create_table "exports", id: :serial, force: :cascade do |t|
    t.string "category"
    t.string "export_type"
    t.string "query"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "key"
    t.string "extension", default: "xlsx"
    t.index ["user_id"], name: "index_exports_on_user_id"
  end

  create_table "footprint_debugs", force: :cascade do |t|
    t.string "footprint"
    t.string "data"
    t.string "klass"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.boolean "disabled"
    t.index ["slug"], name: "index_groups_on_slug", unique: true
  end

  create_table "history_values", id: :serial, force: :cascade do |t|
    t.integer "setting_id"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "footprint"
    t.integer "invoicing_profile_id"
    t.index ["invoicing_profile_id"], name: "index_history_values_on_invoicing_profile_id"
    t.index ["setting_id"], name: "index_history_values_on_setting_id"
  end

  create_table "i_calendar_events", id: :serial, force: :cascade do |t|
    t.string "uid"
    t.datetime "dtstart"
    t.datetime "dtend"
    t.string "summary"
    t.string "description"
    t.string "attendee"
    t.integer "i_calendar_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["i_calendar_id"], name: "index_i_calendar_events_on_i_calendar_id"
  end

  create_table "i_calendars", id: :serial, force: :cascade do |t|
    t.string "url"
    t.string "name"
    t.string "color"
    t.string "text_color"
    t.boolean "text_hidden"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "imports", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "attachment"
    t.string "update_field"
    t.string "category"
    t.text "results"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoice_items", id: :serial, force: :cascade do |t|
    t.integer "invoice_id"
    t.integer "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.integer "invoice_item_id"
    t.string "footprint"
    t.string "object_type", null: false
    t.bigint "object_id", null: false
    t.boolean "main"
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["object_type", "object_id"], name: "index_invoice_items_on_object_type_and_object_id"
  end

  create_table "invoices", id: :serial, force: :cascade do |t|
    t.integer "total"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "reference"
    t.string "payment_method"
    t.datetime "avoir_date"
    t.integer "invoice_id"
    t.string "type"
    t.boolean "subscription_to_expire"
    t.text "description"
    t.integer "wallet_amount"
    t.integer "wallet_transaction_id"
    t.integer "coupon_id"
    t.string "footprint"
    t.string "environment"
    t.integer "invoicing_profile_id"
    t.integer "operator_profile_id"
    t.integer "statistic_profile_id"
    t.index ["coupon_id"], name: "index_invoices_on_coupon_id"
    t.index ["invoice_id"], name: "index_invoices_on_invoice_id"
    t.index ["invoicing_profile_id"], name: "index_invoices_on_invoicing_profile_id"
    t.index ["statistic_profile_id"], name: "index_invoices_on_statistic_profile_id"
    t.index ["wallet_transaction_id"], name: "index_invoices_on_wallet_transaction_id"
  end

  create_table "invoicing_profiles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.index ["external_id"], name: "unique_not_null_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["user_id"], name: "index_invoicing_profiles_on_user_id"
  end

  create_table "licences", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
  end

  create_table "machine_categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "machines", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.text "spec"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.boolean "disabled"
    t.datetime "deleted_at"
    t.bigint "machine_category_id"
    t.boolean "reservable", default: true
    t.index ["deleted_at"], name: "index_machines_on_deleted_at"
    t.index ["machine_category_id"], name: "index_machines_on_machine_category_id"
    t.index ["slug"], name: "index_machines_on_slug", unique: true
  end

  create_table "machines_availabilities", id: :serial, force: :cascade do |t|
    t.integer "machine_id"
    t.integer "availability_id"
    t.index ["availability_id"], name: "index_machines_availabilities_on_availability_id"
    t.index ["machine_id"], name: "index_machines_availabilities_on_machine_id"
  end

  create_table "machines_products", id: false, force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "machine_id", null: false
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "notification_type_id", null: false
    t.boolean "in_system", default: true
    t.boolean "email", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_type_id"], name: "index_notification_preferences_on_notification_type_id"
    t.index ["user_id", "notification_type_id"], name: "index_notification_preferences_on_user_and_notification_type", unique: true
  end

  create_table "notification_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "category", null: false
    t.boolean "is_configurable", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_notification_types_on_name", unique: true
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "receiver_id"
    t.string "attached_object_type"
    t.integer "attached_object_id"
    t.integer "notification_type_id"
    t.boolean "is_read", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "receiver_type"
    t.boolean "is_send", default: false
    t.jsonb "meta_data", default: "{}"
    t.index ["notification_type_id"], name: "index_notifications_on_notification_type_id"
    t.index ["receiver_id"], name: "index_notifications_on_receiver_id"
  end

  create_table "o_auth2_providers", id: :serial, force: :cascade do |t|
    t.string "base_url"
    t.string "token_endpoint"
    t.string "authorization_endpoint"
    t.string "client_id"
    t.string "client_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "profile_url"
    t.string "scopes"
  end

  create_table "offer_days", id: :serial, force: :cascade do |t|
    t.integer "subscription_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["subscription_id"], name: "index_offer_days_on_subscription_id"
  end

  create_table "open_api_clients", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "calls_count", default: 0
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "open_id_connect_providers", force: :cascade do |t|
    t.string "issuer"
    t.boolean "discovery"
    t.string "client_auth_method"
    t.string "scope", array: true
    t.string "response_type"
    t.string "response_mode"
    t.string "display"
    t.string "prompt"
    t.boolean "send_scope_to_token_endpoint"
    t.string "post_logout_redirect_uri"
    t.string "uid_field"
    t.string "client__identifier"
    t.string "client__secret"
    t.string "client__redirect_uri"
    t.string "client__scheme"
    t.string "client__host"
    t.string "client__port"
    t.string "client__authorization_endpoint"
    t.string "client__token_endpoint"
    t.string "client__userinfo_endpoint"
    t.string "client__jwks_uri"
    t.string "client__end_session_endpoint"
    t.string "profile_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_activities", force: :cascade do |t|
    t.bigint "order_id"
    t.bigint "operator_profile_id"
    t.string "activity_type"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["operator_profile_id"], name: "index_order_activities_on_operator_profile_id"
    t.index ["order_id"], name: "index_order_activities_on_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id"
    t.string "orderable_type"
    t.bigint "orderable_id"
    t.integer "amount"
    t.integer "quantity"
    t.boolean "is_offered"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["orderable_type", "orderable_id"], name: "index_order_items_on_orderable_type_and_orderable_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "statistic_profile_id"
    t.integer "operator_profile_id"
    t.string "token"
    t.string "reference"
    t.string "state"
    t.integer "total"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "wallet_amount"
    t.integer "wallet_transaction_id"
    t.string "payment_method"
    t.string "footprint"
    t.string "environment"
    t.bigint "coupon_id"
    t.integer "paid_total"
    t.bigint "invoice_id"
    t.index ["coupon_id"], name: "index_orders_on_coupon_id"
    t.index ["invoice_id"], name: "index_orders_on_invoice_id"
    t.index ["operator_profile_id"], name: "index_orders_on_operator_profile_id"
    t.index ["statistic_profile_id"], name: "index_orders_on_statistic_profile_id"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "invoicing_profile_id"
    t.index ["invoicing_profile_id"], name: "index_organizations_on_invoicing_profile_id"
  end

  create_table "payment_gateway_objects", force: :cascade do |t|
    t.string "gateway_object_id"
    t.string "gateway_object_type"
    t.string "item_type"
    t.bigint "item_id"
    t.bigint "payment_gateway_object_id"
    t.index ["item_type", "item_id"], name: "index_payment_gateway_objects_on_item_type_and_item_id"
    t.index ["payment_gateway_object_id"], name: "index_payment_gateway_objects_on_payment_gateway_object_id"
  end

  create_table "payment_schedule_items", force: :cascade do |t|
    t.integer "amount"
    t.datetime "due_date"
    t.string "state", default: "new"
    t.jsonb "details", default: "{}"
    t.string "payment_method"
    t.string "client_secret"
    t.bigint "payment_schedule_id"
    t.bigint "invoice_id"
    t.string "footprint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_payment_schedule_items_on_invoice_id"
    t.index ["payment_schedule_id"], name: "index_payment_schedule_items_on_payment_schedule_id"
  end

  create_table "payment_schedule_objects", force: :cascade do |t|
    t.string "object_type"
    t.bigint "object_id"
    t.bigint "payment_schedule_id"
    t.boolean "main"
    t.string "footprint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["object_type", "object_id"], name: "index_payment_schedule_objects_on_object_type_and_object_id"
    t.index ["payment_schedule_id"], name: "index_payment_schedule_objects_on_payment_schedule_id"
  end

  create_table "payment_schedules", force: :cascade do |t|
    t.integer "total"
    t.string "reference"
    t.string "payment_method"
    t.integer "wallet_amount"
    t.bigint "wallet_transaction_id"
    t.bigint "coupon_id"
    t.string "footprint"
    t.string "environment"
    t.bigint "invoicing_profile_id"
    t.bigint "statistic_profile_id"
    t.bigint "operator_profile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "start_at"
    t.index ["coupon_id"], name: "index_payment_schedules_on_coupon_id"
    t.index ["invoicing_profile_id"], name: "index_payment_schedules_on_invoicing_profile_id"
    t.index ["operator_profile_id"], name: "index_payment_schedules_on_operator_profile_id"
    t.index ["statistic_profile_id"], name: "index_payment_schedules_on_statistic_profile_id"
    t.index ["wallet_transaction_id"], name: "index_payment_schedules_on_wallet_transaction_id"
  end

  create_table "plan_categories", force: :cascade do |t|
    t.string "name"
    t.integer "weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
  end

  create_table "plan_limitations", force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.string "limitable_type", null: false
    t.bigint "limitable_id", null: false
    t.integer "limit", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["limitable_type", "limitable_id"], name: "index_plan_limitations_on_limitable_type_and_limitable_id"
    t.index ["plan_id", "limitable_id", "limitable_type"], name: "index_plan_limitations_on_plan_and_limitable", unique: true
    t.index ["plan_id"], name: "index_plan_limitations_on_plan_id"
  end

  create_table "plans", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "amount"
    t.string "interval"
    t.integer "group_id"
    t.string "stp_plan_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "training_credit_nb", default: 0
    t.boolean "is_rolling"
    t.text "description"
    t.string "type"
    t.string "base_name"
    t.integer "ui_weight", default: 0
    t.integer "interval_count", default: 1
    t.string "slug"
    t.boolean "disabled"
    t.boolean "monthly_payment"
    t.bigint "plan_category_id"
    t.boolean "limiting"
    t.integer "machines_visibility"
    t.index ["group_id"], name: "index_plans_on_group_id"
    t.index ["plan_category_id"], name: "index_plans_on_plan_category_id"
  end

  create_table "plans_availabilities", id: :serial, force: :cascade do |t|
    t.integer "plan_id"
    t.integer "availability_id"
    t.index ["availability_id"], name: "index_plans_availabilities_on_availability_id"
    t.index ["plan_id"], name: "index_plans_availabilities_on_plan_id"
  end

  create_table "prepaid_pack_reservations", force: :cascade do |t|
    t.bigint "statistic_profile_prepaid_pack_id"
    t.bigint "reservation_id"
    t.integer "consumed_minutes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reservation_id"], name: "index_prepaid_pack_reservations_on_reservation_id"
    t.index ["statistic_profile_prepaid_pack_id"], name: "index_prepaid_pack_reservations_on_sp_prepaid_pack_id"
  end

  create_table "prepaid_packs", force: :cascade do |t|
    t.string "priceable_type"
    t.bigint "priceable_id"
    t.bigint "group_id"
    t.integer "amount"
    t.integer "minutes"
    t.string "validity_interval"
    t.integer "validity_count"
    t.boolean "disabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_prepaid_packs_on_group_id"
    t.index ["priceable_type", "priceable_id"], name: "index_prepaid_packs_on_priceable_type_and_priceable_id"
  end

  create_table "price_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "conditions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_price_categories_on_name", unique: true
  end

  create_table "prices", id: :serial, force: :cascade do |t|
    t.integer "group_id"
    t.integer "plan_id"
    t.string "priceable_type"
    t.integer "priceable_id"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "duration", default: 60
    t.index ["group_id"], name: "index_prices_on_group_id"
    t.index ["plan_id", "priceable_id", "priceable_type", "group_id", "duration"], name: "index_prices_on_plan_priceable_group_and_duration", unique: true
    t.index ["plan_id"], name: "index_prices_on_plan_id"
    t.index ["priceable_type", "priceable_id"], name: "index_prices_on_priceable_type_and_priceable_id"
  end

  create_table "product_categories", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.integer "parent_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_product_categories_on_parent_id"
    t.index ["slug"], name: "index_product_categories_on_slug", unique: true
  end

  create_table "product_stock_movements", force: :cascade do |t|
    t.bigint "product_id"
    t.integer "quantity"
    t.string "reason"
    t.string "stock_type"
    t.integer "remaining_stock"
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order_item_id"
    t.index ["product_id"], name: "index_product_stock_movements_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "sku"
    t.text "description"
    t.boolean "is_active", default: false
    t.bigint "product_category_id"
    t.integer "amount"
    t.integer "quantity_min"
    t.jsonb "stock", default: {"external"=>0, "internal"=>0}
    t.boolean "low_stock_alert", default: false
    t.integer "low_stock_threshold"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_category_id"], name: "index_products_on_product_category_id"
    t.index ["slug"], name: "index_products_on_slug", unique: true
  end

  create_table "profile_custom_fields", force: :cascade do |t|
    t.string "label"
    t.boolean "required", default: false
    t.boolean "actived", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "profiles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.text "interest"
    t.text "software_mastered"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "facebook"
    t.string "twitter"
    t.string "google_plus"
    t.string "viadeo"
    t.string "linkedin"
    t.string "instagram"
    t.string "youtube"
    t.string "vimeo"
    t.string "dailymotion"
    t.string "github"
    t.string "echosciences"
    t.string "website"
    t.string "pinterest"
    t.string "lastfm"
    t.string "flickr"
    t.string "job"
    t.string "tours"
    t.text "note"
    t.index "lower(f_unaccent((first_name)::text)) gin_trgm_ops", name: "profiles_lower_unaccent_first_name_trgm_idx", using: :gin
    t.index "lower(f_unaccent((last_name)::text)) gin_trgm_ops", name: "profiles_lower_unaccent_last_name_trgm_idx", using: :gin
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "project_steps", id: :serial, force: :cascade do |t|
    t.text "description"
    t.integer "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "title"
    t.integer "step_nb"
    t.index ["project_id"], name: "index_project_steps_on_project_id"
  end

  create_table "project_users", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_valid", default: false
    t.string "valid_token"
    t.index ["project_id"], name: "index_project_users_on_project_id"
    t.index ["user_id"], name: "index_project_users_on_user_id"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "tags"
    t.integer "licence_id"
    t.string "state"
    t.string "slug"
    t.datetime "published_at"
    t.integer "author_statistic_profile_id"
    t.tsvector "search_vector"
    t.bigint "status_id"
    t.index ["search_vector"], name: "projects_search_vector_idx", using: :gin
    t.index ["slug"], name: "index_projects_on_slug", unique: true
    t.index ["status_id"], name: "index_projects_on_status_id"
  end

  create_table "projects_components", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "component_id"
    t.index ["component_id"], name: "index_projects_components_on_component_id"
    t.index ["project_id"], name: "index_projects_components_on_project_id"
  end

  create_table "projects_machines", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "machine_id"
    t.index ["machine_id"], name: "index_projects_machines_on_machine_id"
    t.index ["project_id"], name: "index_projects_machines_on_project_id"
  end

  create_table "projects_spaces", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "space_id"
    t.index ["project_id"], name: "index_projects_spaces_on_project_id"
    t.index ["space_id"], name: "index_projects_spaces_on_space_id"
  end

  create_table "projects_themes", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "theme_id"
    t.index ["project_id"], name: "index_projects_themes_on_project_id"
    t.index ["theme_id"], name: "index_projects_themes_on_theme_id"
  end

  create_table "reservations", id: :serial, force: :cascade do |t|
    t.text "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "reservable_type"
    t.integer "reservable_id"
    t.integer "nb_reserve_places"
    t.integer "statistic_profile_id"
    t.index ["reservable_type", "reservable_id"], name: "index_reservations_on_reservable_type_and_reservable_id"
    t.index ["statistic_profile_id"], name: "index_reservations_on_statistic_profile_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.integer "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_settings_on_name", unique: true
  end

  create_table "slots", id: :serial, force: :cascade do |t|
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "availability_id", null: false
    t.jsonb "places", default: [], null: false
    t.index ["availability_id"], name: "index_slots_on_availability_id"
    t.index ["places"], name: "index_slots_on_places", using: :gin
  end

  create_table "slots_reservations", id: :serial, force: :cascade do |t|
    t.integer "slot_id", null: false
    t.integer "reservation_id", null: false
    t.datetime "ex_start_at"
    t.datetime "ex_end_at"
    t.datetime "canceled_at"
    t.boolean "offered", default: false
    t.index ["reservation_id"], name: "index_slots_reservations_on_reservation_id"
    t.index ["slot_id"], name: "index_slots_reservations_on_slot_id"
  end

  create_table "spaces", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "default_places"
    t.text "description"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "characteristics"
    t.boolean "disabled"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_spaces_on_deleted_at"
  end

  create_table "spaces_availabilities", id: :serial, force: :cascade do |t|
    t.integer "space_id"
    t.integer "availability_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["availability_id"], name: "index_spaces_availabilities_on_availability_id"
    t.index ["space_id"], name: "index_spaces_availabilities_on_space_id"
  end

  create_table "statistic_custom_aggregations", id: :serial, force: :cascade do |t|
    t.text "query"
    t.integer "statistic_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "field"
    t.string "es_index"
    t.string "es_type"
    t.index ["statistic_type_id"], name: "index_statistic_custom_aggregations_on_statistic_type_id"
  end

  create_table "statistic_fields", id: :serial, force: :cascade do |t|
    t.integer "statistic_index_id"
    t.string "key"
    t.string "label"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "data_type"
    t.index ["statistic_index_id"], name: "index_statistic_fields_on_statistic_index_id"
  end

  create_table "statistic_graphs", id: :serial, force: :cascade do |t|
    t.integer "statistic_index_id"
    t.string "chart_type"
    t.integer "limit"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["statistic_index_id"], name: "index_statistic_graphs_on_statistic_index_id"
  end

  create_table "statistic_indices", id: :serial, force: :cascade do |t|
    t.string "es_type_key"
    t.string "label"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "table", default: true
    t.boolean "ca", default: true
  end

  create_table "statistic_profile_prepaid_packs", force: :cascade do |t|
    t.bigint "prepaid_pack_id"
    t.bigint "statistic_profile_id"
    t.integer "minutes_used", default: 0
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prepaid_pack_id"], name: "index_statistic_profile_prepaid_packs_on_prepaid_pack_id"
    t.index ["statistic_profile_id"], name: "index_statistic_profile_prepaid_packs_on_statistic_profile_id"
  end

  create_table "statistic_profile_trainings", id: :serial, force: :cascade do |t|
    t.integer "statistic_profile_id"
    t.integer "training_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["statistic_profile_id"], name: "index_statistic_profile_trainings_on_statistic_profile_id"
    t.index ["training_id"], name: "index_statistic_profile_trainings_on_training_id"
  end

  create_table "statistic_profiles", id: :serial, force: :cascade do |t|
    t.boolean "gender"
    t.date "birthday"
    t.integer "group_id"
    t.integer "user_id"
    t.integer "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["group_id"], name: "index_statistic_profiles_on_group_id"
    t.index ["role_id"], name: "index_statistic_profiles_on_role_id"
    t.index ["user_id"], name: "index_statistic_profiles_on_user_id"
  end

  create_table "statistic_sub_types", id: :serial, force: :cascade do |t|
    t.string "key"
    t.string "label"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "statistic_type_sub_types", id: :serial, force: :cascade do |t|
    t.integer "statistic_type_id"
    t.integer "statistic_sub_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["statistic_sub_type_id"], name: "index_statistic_type_sub_types_on_statistic_sub_type_id"
    t.index ["statistic_type_id"], name: "index_statistic_type_sub_types_on_statistic_type_id"
  end

  create_table "statistic_types", id: :serial, force: :cascade do |t|
    t.integer "statistic_index_id"
    t.string "key"
    t.string "label"
    t.boolean "graph"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "simple"
    t.index ["statistic_index_id"], name: "index_statistic_types_on_statistic_index_id"
  end

  create_table "statuses", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stylesheets", id: :serial, force: :cascade do |t|
    t.text "contents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "plan_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "expiration_date"
    t.datetime "canceled_at"
    t.integer "statistic_profile_id"
    t.datetime "start_at"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["statistic_profile_id"], name: "index_subscriptions_on_statistic_profile_id"
  end

  create_table "supporting_document_files", force: :cascade do |t|
    t.bigint "supporting_document_type_id"
    t.bigint "user_id"
    t.string "attachment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supporting_document_type_id"], name: "index_supporting_document_files_on_supporting_document_type_id"
    t.index ["user_id"], name: "index_supporting_document_files_on_user_id"
  end

  create_table "supporting_document_refusals", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "operator_id"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_supporting_document_refusals_on_user_id"
  end

  create_table "supporting_document_refusals_types", id: false, force: :cascade do |t|
    t.bigint "supporting_document_type_id", null: false
    t.bigint "supporting_document_refusal_id", null: false
    t.index ["supporting_document_type_id", "supporting_document_refusal_id"], name: "proof_of_identity_type_id_and_proof_of_identity_refusal_id"
  end

  create_table "supporting_document_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "supporting_document_types_groups", force: :cascade do |t|
    t.bigint "supporting_document_type_id"
    t.bigint "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_p_o_i_t_groups_on_group_id"
    t.index ["supporting_document_type_id"], name: "index_p_o_i_t_groups_on_proof_of_identity_type_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "themes", id: :serial, force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "tickets", id: :serial, force: :cascade do |t|
    t.integer "reservation_id"
    t.integer "event_price_category_id"
    t.integer "booked"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_price_category_id"], name: "index_tickets_on_event_price_category_id"
    t.index ["reservation_id"], name: "index_tickets_on_reservation_id"
  end

  create_table "trainings", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "nb_total_places"
    t.string "slug"
    t.text "description"
    t.boolean "public_page", default: true
    t.boolean "disabled"
    t.boolean "auto_cancel"
    t.integer "auto_cancel_threshold"
    t.integer "auto_cancel_deadline"
    t.boolean "authorization"
    t.integer "authorization_period"
    t.boolean "invalidation"
    t.integer "invalidation_period"
    t.index ["slug"], name: "index_trainings_on_slug", unique: true
  end

  create_table "trainings_availabilities", id: :serial, force: :cascade do |t|
    t.integer "training_id"
    t.integer "availability_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["availability_id"], name: "index_trainings_availabilities_on_availability_id"
    t.index ["training_id"], name: "index_trainings_availabilities_on_training_id"
  end

  create_table "trainings_machines", id: :serial, force: :cascade do |t|
    t.integer "training_id"
    t.integer "machine_id"
    t.index ["machine_id"], name: "index_trainings_machines_on_machine_id"
    t.index ["training_id"], name: "index_trainings_machines_on_training_id"
  end

  create_table "trainings_pricings", id: :serial, force: :cascade do |t|
    t.integer "group_id"
    t.integer "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "training_id"
    t.index ["group_id"], name: "index_trainings_pricings_on_group_id"
    t.index ["training_id"], name: "index_trainings_pricings_on_training_id"
  end

  create_table "user_profile_custom_fields", force: :cascade do |t|
    t.bigint "invoicing_profile_id"
    t.bigint "profile_custom_field_id"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoicing_profile_id"], name: "index_user_profile_custom_fields_on_invoicing_profile_id"
    t.index ["profile_custom_field_id"], name: "index_user_profile_custom_fields_on_profile_custom_field_id"
  end

  create_table "user_tags", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_user_tags_on_tag_id"
    t.index ["user_id"], name: "index_user_tags_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_allow_contact", default: true
    t.integer "group_id"
    t.string "username"
    t.string "slug"
    t.boolean "is_active", default: true
    t.string "provider"
    t.string "uid"
    t.string "auth_token"
    t.datetime "merged_at"
    t.boolean "is_allow_newsletter"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "mapped_from_sso"
    t.datetime "validated_at"
    t.index ["auth_token"], name: "index_users_on_auth_token"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["group_id"], name: "index_users_on_group_id"
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
    t.index ["uid"], name: "index_users_on_uid"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "users_credits", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "credit_id"
    t.integer "hours_used"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["credit_id"], name: "index_users_credits_on_credit_id"
    t.index ["user_id"], name: "index_users_credits_on_user_id"
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  create_table "wallet_transactions", id: :serial, force: :cascade do |t|
    t.integer "wallet_id"
    t.string "transaction_type"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "invoicing_profile_id"
    t.index ["invoicing_profile_id"], name: "index_wallet_transactions_on_invoicing_profile_id"
    t.index ["wallet_id"], name: "index_wallet_transactions_on_wallet_id"
  end

  create_table "wallets", id: :serial, force: :cascade do |t|
    t.integer "amount", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "invoicing_profile_id"
    t.index ["invoicing_profile_id"], name: "index_wallets_on_invoicing_profile_id"
  end

  add_foreign_key "accounting_lines", "invoices"
  add_foreign_key "accounting_lines", "invoicing_profiles"
  add_foreign_key "accounting_periods", "users", column: "closed_by"
  add_foreign_key "auth_provider_mappings", "auth_providers"
  add_foreign_key "availability_tags", "availabilities"
  add_foreign_key "availability_tags", "tags"
  add_foreign_key "cart_item_coupons", "coupons"
  add_foreign_key "cart_item_coupons", "invoicing_profiles", column: "customer_profile_id"
  add_foreign_key "cart_item_coupons", "invoicing_profiles", column: "operator_profile_id"
  add_foreign_key "cart_item_event_reservation_tickets", "cart_item_event_reservations"
  add_foreign_key "cart_item_event_reservation_tickets", "event_price_categories"
  add_foreign_key "cart_item_event_reservations", "events"
  add_foreign_key "cart_item_event_reservations", "invoicing_profiles", column: "customer_profile_id"
  add_foreign_key "cart_item_event_reservations", "invoicing_profiles", column: "operator_profile_id"
  add_foreign_key "cart_item_free_extensions", "invoicing_profiles", column: "customer_profile_id"
  add_foreign_key "cart_item_free_extensions", "subscriptions"
  add_foreign_key "cart_item_payment_schedules", "coupons"
  add_foreign_key "cart_item_payment_schedules", "invoicing_profiles", column: "customer_profile_id"
  add_foreign_key "cart_item_payment_schedules", "plans"
  add_foreign_key "cart_item_prepaid_packs", "invoicing_profiles", column: "customer_profile_id"
  add_foreign_key "cart_item_prepaid_packs", "prepaid_packs"
  add_foreign_key "cart_item_reservation_slots", "slots"
  add_foreign_key "cart_item_reservation_slots", "slots_reservations"
  add_foreign_key "cart_item_reservations", "invoicing_profiles", column: "customer_profile_id"
  add_foreign_key "cart_item_reservations", "invoicing_profiles", column: "operator_profile_id"
  add_foreign_key "cart_item_reservations", "plans"
  add_foreign_key "cart_item_subscriptions", "invoicing_profiles", column: "customer_profile_id"
  add_foreign_key "cart_item_subscriptions", "plans"
  add_foreign_key "event_price_categories", "events"
  add_foreign_key "event_price_categories", "price_categories"
  add_foreign_key "events", "categories"
  add_foreign_key "events_event_themes", "event_themes"
  add_foreign_key "events_event_themes", "events"
  add_foreign_key "exports", "users"
  add_foreign_key "history_values", "invoicing_profiles"
  add_foreign_key "history_values", "settings"
  add_foreign_key "i_calendar_events", "i_calendars"
  add_foreign_key "invoices", "coupons"
  add_foreign_key "invoices", "invoicing_profiles"
  add_foreign_key "invoices", "invoicing_profiles", column: "operator_profile_id"
  add_foreign_key "invoices", "statistic_profiles"
  add_foreign_key "invoices", "wallet_transactions"
  add_foreign_key "invoicing_profiles", "users"
  add_foreign_key "machines", "machine_categories"
  add_foreign_key "notification_preferences", "notification_types"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "notification_types"
  add_foreign_key "order_activities", "invoicing_profiles", column: "operator_profile_id"
  add_foreign_key "order_activities", "orders"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "coupons"
  add_foreign_key "orders", "invoices"
  add_foreign_key "orders", "invoicing_profiles", column: "operator_profile_id"
  add_foreign_key "orders", "statistic_profiles"
  add_foreign_key "organizations", "invoicing_profiles"
  add_foreign_key "payment_gateway_objects", "payment_gateway_objects"
  add_foreign_key "payment_schedule_items", "invoices"
  add_foreign_key "payment_schedule_items", "payment_schedules"
  add_foreign_key "payment_schedule_objects", "payment_schedules"
  add_foreign_key "payment_schedules", "coupons"
  add_foreign_key "payment_schedules", "invoicing_profiles"
  add_foreign_key "payment_schedules", "invoicing_profiles", column: "operator_profile_id"
  add_foreign_key "payment_schedules", "statistic_profiles"
  add_foreign_key "payment_schedules", "wallet_transactions"
  add_foreign_key "plan_limitations", "plans"
  add_foreign_key "plans", "plan_categories"
  add_foreign_key "prepaid_pack_reservations", "reservations"
  add_foreign_key "prepaid_pack_reservations", "statistic_profile_prepaid_packs"
  add_foreign_key "prepaid_packs", "groups"
  add_foreign_key "prices", "groups"
  add_foreign_key "prices", "plans"
  add_foreign_key "product_stock_movements", "products"
  add_foreign_key "products", "product_categories"
  add_foreign_key "project_steps", "projects"
  add_foreign_key "project_users", "projects"
  add_foreign_key "project_users", "users"
  add_foreign_key "projects", "statistic_profiles", column: "author_statistic_profile_id"
  add_foreign_key "projects", "statuses"
  add_foreign_key "projects_components", "components"
  add_foreign_key "projects_components", "projects"
  add_foreign_key "projects_machines", "machines"
  add_foreign_key "projects_machines", "projects"
  add_foreign_key "projects_spaces", "projects"
  add_foreign_key "projects_spaces", "spaces"
  add_foreign_key "projects_themes", "projects"
  add_foreign_key "projects_themes", "themes"
  add_foreign_key "reservations", "statistic_profiles"
  add_foreign_key "slots_reservations", "reservations"
  add_foreign_key "slots_reservations", "slots"
  add_foreign_key "spaces_availabilities", "availabilities"
  add_foreign_key "spaces_availabilities", "spaces"
  add_foreign_key "statistic_custom_aggregations", "statistic_types"
  add_foreign_key "statistic_profile_prepaid_packs", "prepaid_packs"
  add_foreign_key "statistic_profile_prepaid_packs", "statistic_profiles"
  add_foreign_key "statistic_profile_trainings", "statistic_profiles"
  add_foreign_key "statistic_profile_trainings", "trainings"
  add_foreign_key "statistic_profiles", "groups"
  add_foreign_key "statistic_profiles", "roles"
  add_foreign_key "statistic_profiles", "users"
  add_foreign_key "subscriptions", "statistic_profiles"
  add_foreign_key "supporting_document_refusals", "users"
  add_foreign_key "supporting_document_types_groups", "groups"
  add_foreign_key "supporting_document_types_groups", "supporting_document_types"
  add_foreign_key "tickets", "event_price_categories"
  add_foreign_key "tickets", "reservations"
  add_foreign_key "user_profile_custom_fields", "invoicing_profiles"
  add_foreign_key "user_profile_custom_fields", "profile_custom_fields"
  add_foreign_key "user_tags", "tags"
  add_foreign_key "user_tags", "users"
  add_foreign_key "wallet_transactions", "invoicing_profiles"
  add_foreign_key "wallet_transactions", "wallets"
  add_foreign_key "wallets", "invoicing_profiles"
end
