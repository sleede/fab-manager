# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20170109085345) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_trgm"
  enable_extension "unaccent"

  create_table "abuses", force: :cascade do |t|
    t.integer  "signaled_id"
    t.string   "signaled_type"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.text     "message"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "abuses", ["signaled_type", "signaled_id"], name: "index_abuses_on_signaled_type_and_signaled_id", using: :btree

  create_table "addresses", force: :cascade do |t|
    t.string   "address",        limit: 255
    t.string   "street_number",  limit: 255
    t.string   "route",          limit: 255
    t.string   "locality",       limit: 255
    t.string   "country",        limit: 255
    t.string   "postal_code",    limit: 255
    t.integer  "placeable_id"
    t.string   "placeable_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "age_ranges", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "slug"
  end

  add_index "age_ranges", ["slug"], name: "index_age_ranges_on_slug", unique: true, using: :btree

  create_table "assets", force: :cascade do |t|
    t.integer  "viewable_id"
    t.string   "viewable_type", limit: 255
    t.string   "attachment",    limit: 255
    t.string   "type",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "auth_providers", force: :cascade do |t|
    t.string   "name"
    t.string   "status"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "providable_type"
    t.integer  "providable_id"
  end

  create_table "availabilities", force: :cascade do |t|
    t.datetime "start_at"
    t.datetime "end_at"
    t.string   "available_type",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "nb_total_places"
    t.boolean  "destroying",                  default: false
  end

  create_table "availability_tags", force: :cascade do |t|
    t.integer  "availability_id"
    t.integer  "tag_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "availability_tags", ["availability_id"], name: "index_availability_tags_on_availability_id", using: :btree
  add_index "availability_tags", ["tag_id"], name: "index_availability_tags_on_tag_id", using: :btree

  create_table "categories", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "categories", ["slug"], name: "index_categories_on_slug", unique: true, using: :btree

  create_table "components", force: :cascade do |t|
    t.string "name", limit: 255, null: false
  end

  create_table "coupons", force: :cascade do |t|
    t.string   "name"
    t.string   "code"
    t.integer  "percent_off"
    t.datetime "valid_until"
    t.integer  "max_usages"
    t.boolean  "active"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "validity_per_user"
    t.integer  "amount_off"
  end

  create_table "credits", force: :cascade do |t|
    t.integer  "creditable_id"
    t.string   "creditable_type", limit: 255
    t.integer  "plan_id"
    t.integer  "hours"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "credits", ["plan_id"], name: "index_credits_on_plan_id", using: :btree

  create_table "custom_assets", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "database_providers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "event_price_categories", force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "price_category_id"
    t.integer  "amount"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "event_price_categories", ["event_id"], name: "index_event_price_categories_on_event_id", using: :btree
  add_index "event_price_categories", ["price_category_id"], name: "index_event_price_categories_on_price_category_id", using: :btree

  create_table "event_themes", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "slug"
  end

  add_index "event_themes", ["slug"], name: "index_event_themes_on_slug", unique: true, using: :btree

  create_table "events", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "availability_id"
    t.integer  "amount"
    t.integer  "nb_total_places"
    t.integer  "nb_free_places"
    t.integer  "recurrence_id"
    t.integer  "age_range_id"
    t.integer  "category_id"
  end

  add_index "events", ["availability_id"], name: "index_events_on_availability_id", using: :btree
  add_index "events", ["category_id"], name: "index_events_on_category_id", using: :btree
  add_index "events", ["recurrence_id"], name: "index_events_on_recurrence_id", using: :btree

  create_table "events_event_themes", force: :cascade do |t|
    t.integer "event_id"
    t.integer "event_theme_id"
  end

  add_index "events_event_themes", ["event_id"], name: "index_events_event_themes_on_event_id", using: :btree
  add_index "events_event_themes", ["event_theme_id"], name: "index_events_event_themes_on_event_theme_id", using: :btree

  create_table "exports", force: :cascade do |t|
    t.string   "category"
    t.string   "export_type"
    t.string   "query"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "user_id"
    t.string   "key"
  end

  add_index "exports", ["user_id"], name: "index_exports_on_user_id", using: :btree

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 255, null: false
    t.integer  "sluggable_id",               null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope",          limit: 255
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "groups", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug",       limit: 255
  end

  add_index "groups", ["slug"], name: "index_groups_on_slug", unique: true, using: :btree

  create_table "invoice_items", force: :cascade do |t|
    t.integer  "invoice_id"
    t.string   "stp_invoice_item_id", limit: 255
    t.integer  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "subscription_id"
    t.integer  "invoice_item_id"
  end

  add_index "invoice_items", ["invoice_id"], name: "index_invoice_items_on_invoice_id", using: :btree

  create_table "invoices", force: :cascade do |t|
    t.integer  "invoiced_id"
    t.string   "invoiced_type",          limit: 255
    t.string   "stp_invoice_id",         limit: 255
    t.integer  "total"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "reference",              limit: 255
    t.string   "avoir_mode",             limit: 255
    t.datetime "avoir_date"
    t.integer  "invoice_id"
    t.string   "type",                   limit: 255
    t.boolean  "subscription_to_expire"
    t.text     "description"
    t.integer  "wallet_amount"
    t.integer  "wallet_transaction_id"
    t.integer  "coupon_id"
  end

  add_index "invoices", ["coupon_id"], name: "index_invoices_on_coupon_id", using: :btree
  add_index "invoices", ["invoice_id"], name: "index_invoices_on_invoice_id", using: :btree
  add_index "invoices", ["user_id"], name: "index_invoices_on_user_id", using: :btree
  add_index "invoices", ["wallet_transaction_id"], name: "index_invoices_on_wallet_transaction_id", using: :btree

  create_table "licences", force: :cascade do |t|
    t.string "name",        limit: 255, null: false
    t.text   "description"
  end

  create_table "machines", force: :cascade do |t|
    t.string   "name",        limit: 255, null: false
    t.text     "description"
    t.text     "spec"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug",        limit: 255
  end

  add_index "machines", ["slug"], name: "index_machines_on_slug", unique: true, using: :btree

  create_table "machines_availabilities", force: :cascade do |t|
    t.integer "machine_id"
    t.integer "availability_id"
  end

  add_index "machines_availabilities", ["availability_id"], name: "index_machines_availabilities_on_availability_id", using: :btree
  add_index "machines_availabilities", ["machine_id"], name: "index_machines_availabilities_on_machine_id", using: :btree

  create_table "notifications", force: :cascade do |t|
    t.integer  "receiver_id"
    t.integer  "attached_object_id"
    t.string   "attached_object_type", limit: 255
    t.integer  "notification_type_id"
    t.boolean  "is_read",                          default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "receiver_type"
    t.boolean  "is_send",                          default: false
    t.jsonb    "meta_data",                        default: {}
  end

  add_index "notifications", ["notification_type_id"], name: "index_notifications_on_notification_type_id", using: :btree
  add_index "notifications", ["receiver_id"], name: "index_notifications_on_receiver_id", using: :btree

  create_table "o_auth2_mappings", force: :cascade do |t|
    t.integer  "o_auth2_provider_id"
    t.string   "local_field"
    t.string   "api_field"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "local_model"
    t.string   "api_endpoint"
    t.string   "api_data_type"
    t.jsonb    "transformation"
  end

  add_index "o_auth2_mappings", ["o_auth2_provider_id"], name: "index_o_auth2_mappings_on_o_auth2_provider_id", using: :btree

  create_table "o_auth2_providers", force: :cascade do |t|
    t.string   "base_url"
    t.string   "token_endpoint"
    t.string   "authorization_endpoint"
    t.string   "client_id"
    t.string   "client_secret"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "profile_url"
  end

  create_table "offer_days", force: :cascade do |t|
    t.integer  "subscription_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "offer_days", ["subscription_id"], name: "index_offer_days_on_subscription_id", using: :btree

  create_table "open_api_calls_count_tracings", force: :cascade do |t|
    t.integer  "open_api_client_id"
    t.integer  "calls_count",        null: false
    t.datetime "at",                 null: false
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "open_api_calls_count_tracings", ["open_api_client_id"], name: "index_open_api_calls_count_tracings_on_open_api_client_id", using: :btree

  create_table "open_api_clients", force: :cascade do |t|
    t.string   "name"
    t.integer  "calls_count", default: 0
    t.string   "token"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "organizations", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "profile_id"
  end

  add_index "organizations", ["profile_id"], name: "index_organizations_on_profile_id", using: :btree

  create_table "plans", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.integer  "amount"
    t.string   "interval",           limit: 255
    t.integer  "group_id"
    t.string   "stp_plan_id",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "training_credit_nb",             default: 0
    t.boolean  "is_rolling",                     default: true
    t.text     "description"
    t.string   "type"
    t.string   "base_name"
    t.integer  "ui_weight",                      default: 0
    t.integer  "interval_count",                 default: 1
    t.string   "slug"
  end

  add_index "plans", ["group_id"], name: "index_plans_on_group_id", using: :btree

  create_table "price_categories", force: :cascade do |t|
    t.string   "name"
    t.text     "conditions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "prices", force: :cascade do |t|
    t.integer  "group_id"
    t.integer  "plan_id"
    t.integer  "priceable_id"
    t.string   "priceable_type"
    t.integer  "amount"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "prices", ["group_id"], name: "index_prices_on_group_id", using: :btree
  add_index "prices", ["plan_id"], name: "index_prices_on_plan_id", using: :btree
  add_index "prices", ["priceable_type", "priceable_id"], name: "index_prices_on_priceable_type_and_priceable_id", using: :btree

  create_table "profiles", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "first_name",        limit: 255
    t.string   "last_name",         limit: 255
    t.boolean  "gender"
    t.date     "birthday"
    t.string   "phone",             limit: 255
    t.text     "interest"
    t.text     "software_mastered"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "facebook"
    t.string   "twitter"
    t.string   "google_plus"
    t.string   "viadeo"
    t.string   "linkedin"
    t.string   "instagram"
    t.string   "youtube"
    t.string   "vimeo"
    t.string   "dailymotion"
    t.string   "github"
    t.string   "echosciences"
    t.string   "website"
    t.string   "pinterest"
    t.string   "lastfm"
    t.string   "flickr"
    t.string   "job"
  end

  add_index "profiles", ["user_id"], name: "index_profiles_on_user_id", using: :btree

  create_table "project_steps", force: :cascade do |t|
    t.text     "description"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title",       limit: 255
    t.integer  "step_nb"
  end

  add_index "project_steps", ["project_id"], name: "index_project_steps_on_project_id", using: :btree

  create_table "project_users", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_valid",                default: false
    t.string   "valid_token", limit: 255
  end

  add_index "project_users", ["project_id"], name: "index_project_users_on_project_id", using: :btree
  add_index "project_users", ["user_id"], name: "index_project_users_on_user_id", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "author_id"
    t.text     "tags"
    t.integer  "licence_id"
    t.string   "state",        limit: 255
    t.string   "slug",         limit: 255
    t.datetime "published_at"
  end

  add_index "projects", ["slug"], name: "index_projects_on_slug", using: :btree

  create_table "projects_components", force: :cascade do |t|
    t.integer "project_id"
    t.integer "component_id"
  end

  add_index "projects_components", ["component_id"], name: "index_projects_components_on_component_id", using: :btree
  add_index "projects_components", ["project_id"], name: "index_projects_components_on_project_id", using: :btree

  create_table "projects_machines", force: :cascade do |t|
    t.integer "project_id"
    t.integer "machine_id"
  end

  add_index "projects_machines", ["machine_id"], name: "index_projects_machines_on_machine_id", using: :btree
  add_index "projects_machines", ["project_id"], name: "index_projects_machines_on_project_id", using: :btree

  create_table "projects_themes", force: :cascade do |t|
    t.integer "project_id"
    t.integer "theme_id"
  end

  add_index "projects_themes", ["project_id"], name: "index_projects_themes_on_project_id", using: :btree
  add_index "projects_themes", ["theme_id"], name: "index_projects_themes_on_theme_id", using: :btree

  create_table "reservations", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "reservable_id"
    t.string   "reservable_type",   limit: 255
    t.string   "stp_invoice_id",    limit: 255
    t.integer  "nb_reserve_places"
  end

  add_index "reservations", ["reservable_id", "reservable_type"], name: "index_reservations_on_reservable_id_and_reservable_type", using: :btree
  add_index "reservations", ["stp_invoice_id"], name: "index_reservations_on_stp_invoice_id", using: :btree
  add_index "reservations", ["user_id"], name: "index_reservations_on_user_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "resource_id"
    t.string   "resource_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "name",       null: false
    t.text     "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "settings", ["name"], name: "index_settings_on_name", unique: true, using: :btree

  create_table "slots", force: :cascade do |t|
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "reservation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "availability_id"
    t.datetime "ex_start_at"
    t.datetime "ex_end_at"
    t.datetime "canceled_at"
    t.boolean  "offered",         default: false
  end

  add_index "slots", ["availability_id"], name: "index_slots_on_availability_id", using: :btree
  add_index "slots", ["reservation_id"], name: "index_slots_on_reservation_id", using: :btree

  create_table "statistic_custom_aggregations", force: :cascade do |t|
    t.text     "query"
    t.integer  "statistic_type_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "field"
    t.string   "es_index"
    t.string   "es_type"
  end

  add_index "statistic_custom_aggregations", ["statistic_type_id"], name: "index_statistic_custom_aggregations_on_statistic_type_id", using: :btree

  create_table "statistic_fields", force: :cascade do |t|
    t.integer  "statistic_index_id"
    t.string   "key",                limit: 255
    t.string   "label",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "data_type",          limit: 255
  end

  add_index "statistic_fields", ["statistic_index_id"], name: "index_statistic_fields_on_statistic_index_id", using: :btree

  create_table "statistic_graphs", force: :cascade do |t|
    t.integer  "statistic_index_id"
    t.string   "chart_type",         limit: 255
    t.integer  "limit"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "statistic_graphs", ["statistic_index_id"], name: "index_statistic_graphs_on_statistic_index_id", using: :btree

  create_table "statistic_indices", force: :cascade do |t|
    t.string   "es_type_key", limit: 255
    t.string   "label",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "table",                   default: true
    t.boolean  "ca",                      default: true
  end

  create_table "statistic_sub_types", force: :cascade do |t|
    t.string   "key",        limit: 255
    t.string   "label",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "statistic_type_sub_types", force: :cascade do |t|
    t.integer  "statistic_type_id"
    t.integer  "statistic_sub_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "statistic_type_sub_types", ["statistic_sub_type_id"], name: "index_statistic_type_sub_types_on_statistic_sub_type_id", using: :btree
  add_index "statistic_type_sub_types", ["statistic_type_id"], name: "index_statistic_type_sub_types_on_statistic_type_id", using: :btree

  create_table "statistic_types", force: :cascade do |t|
    t.integer  "statistic_index_id"
    t.string   "key",                limit: 255
    t.string   "label",              limit: 255
    t.boolean  "graph"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "simple"
  end

  add_index "statistic_types", ["statistic_index_id"], name: "index_statistic_types_on_statistic_index_id", using: :btree

  create_table "stylesheets", force: :cascade do |t|
    t.text     "contents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "plan_id"
    t.integer  "user_id"
    t.string   "stp_subscription_id", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "expired_at"
    t.datetime "canceled_at"
  end

  add_index "subscriptions", ["plan_id"], name: "index_subscriptions_on_plan_id", using: :btree
  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "themes", force: :cascade do |t|
    t.string "name", limit: 255, null: false
  end

  create_table "tickets", force: :cascade do |t|
    t.integer  "reservation_id"
    t.integer  "event_price_category_id"
    t.integer  "booked"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "tickets", ["event_price_category_id"], name: "index_tickets_on_event_price_category_id", using: :btree
  add_index "tickets", ["reservation_id"], name: "index_tickets_on_reservation_id", using: :btree

  create_table "trainings", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "nb_total_places"
    t.string   "slug",            limit: 255
    t.text     "description"
    t.boolean  "public_page",                 default: true
  end

  add_index "trainings", ["slug"], name: "index_trainings_on_slug", unique: true, using: :btree

  create_table "trainings_availabilities", force: :cascade do |t|
    t.integer  "training_id"
    t.integer  "availability_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "trainings_availabilities", ["availability_id"], name: "index_trainings_availabilities_on_availability_id", using: :btree
  add_index "trainings_availabilities", ["training_id"], name: "index_trainings_availabilities_on_training_id", using: :btree

  create_table "trainings_machines", force: :cascade do |t|
    t.integer "training_id"
    t.integer "machine_id"
  end

  add_index "trainings_machines", ["machine_id"], name: "index_trainings_machines_on_machine_id", using: :btree
  add_index "trainings_machines", ["training_id"], name: "index_trainings_machines_on_training_id", using: :btree

  create_table "trainings_pricings", force: :cascade do |t|
    t.integer  "group_id"
    t.integer  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "training_id"
  end

  add_index "trainings_pricings", ["group_id"], name: "index_trainings_pricings_on_group_id", using: :btree
  add_index "trainings_pricings", ["training_id"], name: "index_trainings_pricings_on_training_id", using: :btree

  create_table "user_tags", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_tags", ["tag_id"], name: "index_user_tags_on_tag_id", using: :btree
  add_index "user_tags", ["user_id"], name: "index_user_tags_on_user_id", using: :btree

  create_table "user_trainings", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "training_id"
  end

  add_index "user_trainings", ["training_id"], name: "index_user_trainings_on_training_id", using: :btree
  add_index "user_trainings", ["user_id"], name: "index_user_trainings_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.integer  "failed_attempts",                    default: 0,     null: false
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_allow_contact",                   default: true
    t.integer  "group_id"
    t.string   "stp_customer_id",        limit: 255
    t.string   "username",               limit: 255
    t.string   "slug",                   limit: 255
    t.boolean  "is_active",                          default: true
    t.boolean  "invoicing_disabled",                 default: false
    t.string   "provider"
    t.string   "uid"
    t.string   "auth_token"
    t.datetime "merged_at"
    t.boolean  "is_allow_newsletter"
  end

  add_index "users", ["auth_token"], name: "index_users_on_auth_token", using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["group_id"], name: "index_users_on_group_id", using: :btree
  add_index "users", ["provider"], name: "index_users_on_provider", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["slug"], name: "index_users_on_slug", unique: true, using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "users_credits", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "credit_id"
    t.integer  "hours_used"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users_credits", ["credit_id"], name: "index_users_credits_on_credit_id", using: :btree
  add_index "users_credits", ["user_id"], name: "index_users_credits_on_user_id", using: :btree

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

  create_table "wallet_transactions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "wallet_id"
    t.integer  "transactable_id"
    t.string   "transactable_type"
    t.string   "transaction_type"
    t.integer  "amount"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "wallet_transactions", ["transactable_type", "transactable_id"], name: "index_wallet_transactions_on_transactable", using: :btree
  add_index "wallet_transactions", ["user_id"], name: "index_wallet_transactions_on_user_id", using: :btree
  add_index "wallet_transactions", ["wallet_id"], name: "index_wallet_transactions_on_wallet_id", using: :btree

  create_table "wallets", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "amount",     default: 0
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "wallets", ["user_id"], name: "index_wallets_on_user_id", using: :btree

  add_foreign_key "availability_tags", "availabilities"
  add_foreign_key "availability_tags", "tags"
  add_foreign_key "event_price_categories", "events"
  add_foreign_key "event_price_categories", "price_categories"
  add_foreign_key "events", "categories"
  add_foreign_key "events_event_themes", "event_themes"
  add_foreign_key "events_event_themes", "events"
  add_foreign_key "exports", "users"
  add_foreign_key "invoices", "coupons"
  add_foreign_key "invoices", "wallet_transactions"
  add_foreign_key "o_auth2_mappings", "o_auth2_providers"
  add_foreign_key "open_api_calls_count_tracings", "open_api_clients"
  add_foreign_key "organizations", "profiles"
  add_foreign_key "prices", "groups"
  add_foreign_key "prices", "plans"
  add_foreign_key "statistic_custom_aggregations", "statistic_types"
  add_foreign_key "tickets", "event_price_categories"
  add_foreign_key "tickets", "reservations"
  add_foreign_key "user_tags", "tags"
  add_foreign_key "user_tags", "users"
  add_foreign_key "wallet_transactions", "users"
  add_foreign_key "wallet_transactions", "wallets"
  add_foreign_key "wallets", "users"
end
