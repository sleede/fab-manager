# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_04_08_101654) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "abuses", id: :serial, force: :cascade do |t|
    t.integer "signaled_id"
    t.string "signaled_type"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["signaled_type", "signaled_id"], name: "index_abuses_on_signaled_type_and_signaled_id"
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
    t.integer "placeable_id"
    t.string "placeable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "age_ranges", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["slug"], name: "index_age_ranges_on_slug", unique: true
  end

  create_table "assets", id: :serial, force: :cascade do |t|
    t.integer "viewable_id"
    t.string "viewable_type"
    t.string "attachment"
    t.string "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "auth_providers", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "providable_type"
    t.integer "providable_id"
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
  end

  create_table "availability_tags", id: :serial, force: :cascade do |t|
    t.integer "availability_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["availability_id"], name: "index_availability_tags_on_availability_id"
    t.index ["tag_id"], name: "index_availability_tags_on_tag_id"
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
  end

  create_table "credits", id: :serial, force: :cascade do |t|
    t.integer "creditable_id"
    t.string "creditable_type"
    t.integer "plan_id"
    t.integer "hours"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.index ["availability_id"], name: "index_events_on_availability_id"
    t.index ["category_id"], name: "index_events_on_category_id"
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
    t.string "stp_invoice_item_id"
    t.integer "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.integer "subscription_id"
    t.integer "invoice_item_id"
    t.string "footprint"
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", id: :serial, force: :cascade do |t|
    t.integer "invoiced_id"
    t.string "invoiced_type"
    t.string "stp_invoice_id"
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
    t.string "stp_payment_intent_id"
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
    t.index ["user_id"], name: "index_invoicing_profiles_on_user_id"
  end

  create_table "licences", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
  end

  create_table "machines", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.text "spec"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.boolean "disabled"
    t.index ["slug"], name: "index_machines_on_slug", unique: true
  end

  create_table "machines_availabilities", id: :serial, force: :cascade do |t|
    t.integer "machine_id"
    t.integer "availability_id"
    t.index ["availability_id"], name: "index_machines_availabilities_on_availability_id"
    t.index ["machine_id"], name: "index_machines_availabilities_on_machine_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "receiver_id"
    t.integer "attached_object_id"
    t.string "attached_object_type"
    t.integer "notification_type_id"
    t.boolean "is_read", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "receiver_type"
    t.boolean "is_send", default: false
    t.jsonb "meta_data", default: {}
    t.index ["notification_type_id"], name: "index_notifications_on_notification_type_id"
    t.index ["receiver_id"], name: "index_notifications_on_receiver_id"
  end

  create_table "o_auth2_mappings", id: :serial, force: :cascade do |t|
    t.integer "o_auth2_provider_id"
    t.string "local_field"
    t.string "api_field"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "local_model"
    t.string "api_endpoint"
    t.string "api_data_type"
    t.jsonb "transformation"
    t.index ["o_auth2_provider_id"], name: "index_o_auth2_mappings_on_o_auth2_provider_id"
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
  end

  create_table "offer_days", id: :serial, force: :cascade do |t|
    t.integer "subscription_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["subscription_id"], name: "index_offer_days_on_subscription_id"
  end

  create_table "open_api_calls_count_tracings", id: :serial, force: :cascade do |t|
    t.integer "open_api_client_id"
    t.integer "calls_count", null: false
    t.datetime "at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["open_api_client_id"], name: "index_open_api_calls_count_tracings_on_open_api_client_id"
  end

  create_table "open_api_clients", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "calls_count", default: 0
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "invoicing_profile_id"
    t.index ["invoicing_profile_id"], name: "index_organizations_on_invoicing_profile_id"
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
    t.boolean "is_rolling", default: true
    t.text "description"
    t.string "type"
    t.string "base_name"
    t.integer "ui_weight", default: 0
    t.integer "interval_count", default: 1
    t.string "slug"
    t.boolean "disabled"
    t.index ["group_id"], name: "index_plans_on_group_id"
  end

  create_table "plans_availabilities", id: :serial, force: :cascade do |t|
    t.integer "plan_id"
    t.integer "availability_id"
    t.index ["availability_id"], name: "index_plans_availabilities_on_availability_id"
    t.index ["plan_id"], name: "index_plans_availabilities_on_plan_id"
  end

  create_table "price_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "conditions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "prices", id: :serial, force: :cascade do |t|
    t.integer "group_id"
    t.integer "plan_id"
    t.integer "priceable_id"
    t.string "priceable_type"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_prices_on_group_id"
    t.index ["plan_id"], name: "index_prices_on_plan_id"
    t.index ["priceable_type", "priceable_id"], name: "index_prices_on_priceable_type_and_priceable_id"
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
    t.index ["slug"], name: "index_projects_on_slug", unique: true
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
    t.integer "reservable_id"
    t.string "reservable_type"
    t.integer "nb_reserve_places"
    t.integer "statistic_profile_id"
    t.index ["reservable_type", "reservable_id"], name: "index_reservations_on_reservable_type_and_reservable_id"
    t.index ["statistic_profile_id"], name: "index_reservations_on_statistic_profile_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "resource_id"
    t.string "resource_type"
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
    t.integer "availability_id"
    t.datetime "ex_start_at"
    t.datetime "ex_end_at"
    t.datetime "canceled_at"
    t.boolean "offered", default: false
    t.boolean "destroying", default: false
    t.index ["availability_id"], name: "index_slots_on_availability_id"
  end

  create_table "slots_reservations", id: :serial, force: :cascade do |t|
    t.integer "slot_id"
    t.integer "reservation_id"
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

  create_table "stylesheets", id: :serial, force: :cascade do |t|
    t.text "contents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "plan_id"
    t.string "stp_subscription_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "expiration_date"
    t.datetime "canceled_at"
    t.integer "statistic_profile_id"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["statistic_profile_id"], name: "index_subscriptions_on_statistic_profile_id"
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
    t.string "stp_customer_id"
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
    t.integer "transactable_id"
    t.string "transactable_type"
    t.string "transaction_type"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "invoicing_profile_id"
    t.index ["invoicing_profile_id"], name: "index_wallet_transactions_on_invoicing_profile_id"
    t.index ["transactable_type", "transactable_id"], name: "index_wallet_transactions_on_transactable"
    t.index ["wallet_id"], name: "index_wallet_transactions_on_wallet_id"
  end

  create_table "wallets", id: :serial, force: :cascade do |t|
    t.integer "amount", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "invoicing_profile_id"
    t.index ["invoicing_profile_id"], name: "index_wallets_on_invoicing_profile_id"
  end

  add_foreign_key "accounting_periods", "users", column: "closed_by"
  add_foreign_key "availability_tags", "availabilities"
  add_foreign_key "availability_tags", "tags"
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
  add_foreign_key "o_auth2_mappings", "o_auth2_providers"
  add_foreign_key "open_api_calls_count_tracings", "open_api_clients"
  add_foreign_key "organizations", "invoicing_profiles"
  add_foreign_key "prices", "groups"
  add_foreign_key "prices", "plans"
  add_foreign_key "project_steps", "projects"
  add_foreign_key "project_users", "projects"
  add_foreign_key "project_users", "users"
  add_foreign_key "projects", "statistic_profiles", column: "author_statistic_profile_id"
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
  add_foreign_key "statistic_profile_trainings", "statistic_profiles"
  add_foreign_key "statistic_profile_trainings", "trainings"
  add_foreign_key "statistic_profiles", "groups"
  add_foreign_key "statistic_profiles", "roles"
  add_foreign_key "statistic_profiles", "users"
  add_foreign_key "subscriptions", "statistic_profiles"
  add_foreign_key "tickets", "event_price_categories"
  add_foreign_key "tickets", "reservations"
  add_foreign_key "user_tags", "tags"
  add_foreign_key "user_tags", "users"
  add_foreign_key "wallet_transactions", "invoicing_profiles"
  add_foreign_key "wallet_transactions", "wallets"
  add_foreign_key "wallets", "invoicing_profiles"
end
