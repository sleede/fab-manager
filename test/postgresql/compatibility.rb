# frozen_string_literal: true

# Run explicitly on a seeded disposable compatibility database, never production.
raise 'Use RAILS_ENV=test and a dedicated fm_pg_a_ database' unless
  ENV['RAILS_ENV'] == 'test' && ENV['PG_COMPAT_DATABASE'].to_s.start_with?('fm_pg_a_')

require_relative '../../config/environment'
require 'minitest/autorun'
require 'sidekiq/testing'
require 'bigdecimal'
require 'tempfile'
require 'securerandom'
require 'open3'

# Seeded scenarios intentionally do not load the unrelated historical invoice fixtures.
class PostgreSQLCompatibilityCase < Minitest::Test
  def setup
    @connection = ActiveRecord::Base.connection
    raise 'Wrong disposable database' unless @connection.current_database == ENV.fetch('PG_COMPAT_DATABASE')
    raise 'External mail must be neutralized' unless ActionMailer::Base.delivery_method == :test

    @connection.begin_transaction(joinable: false)
  end

  def teardown
    @connection.rollback_transaction if @connection&.transaction_open?
  end

  def connection_options
    { host: ENV.fetch('POSTGRES_HOST'), user: ENV.fetch('POSTGRES_USERNAME'),
      password: ENV.fetch('POSTGRES_PASSWORD'), dbname: @connection.current_database, connect_timeout: 2 }
  end

  def session
    @session ||= ActionDispatch::Integration::Session.new(Rails.application)
  end

  def json_headers
    { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }
  end
end

# Active Record type decoding is exercised against a real temporary table.
class PostgreSQLCompatibilityProbe < ApplicationRecord
  self.table_name = 'pg_compatibility_probe'
end

class PostgreSQLTypesCompatibilityTest < PostgreSQLCompatibilityCase
  def test_password_tls_and_parameter_binding
    PG.connect(**connection_options) do |client|
      assert_equal [%w[42 Québec]], client.exec_params('SELECT $1::int::text, $2::text', [42, 'Québec']).values
      assert_equal 'on', client.exec('SELECT ssl FROM pg_stat_ssl WHERE pid=pg_backend_pid()').getvalue(0, 0) == 't' ? 'on' : 'off'
    end
    assert_raises(PG::ConnectionBad) { PG.connect(**connection_options.merge(password: 'synthetic-wrong-password')) }
  end

  def test_extensions_are_available_to_real_queries
    names = @connection.select_values('SELECT extname FROM pg_extension')
    %w[unaccent pg_trgm fuzzystrmatch].each { |name| assert_includes names, name }
    assert_equal 'Elephant cafe', @connection.select_value("SELECT public.f_unaccent('Éléphant café')")
    assert_operator @connection.select_value("SELECT similarity('atelier','atelier')").to_f, :>=, 0.99
    assert_equal 1, @connection.select_value("SELECT levenshtein('cafe','cafez')")
    assert_equal 'ATL', @connection.select_value("SELECT dmetaphone('atelier')")
  end

  def test_json_numeric_dates_indexes_and_sequences
    @connection.execute('CREATE TEMP TABLE pg_compatibility_probe (id bigserial PRIMARY KEY, amount numeric(24,8), ' \
                        'payload json, indexed_payload jsonb, instant timestamptz, day date, bytes bytea) ON COMMIT DROP')
    @connection.execute('CREATE INDEX pg_compatibility_json_idx ON pg_compatibility_probe USING gin(indexed_payload)')
    model = PostgreSQLCompatibilityProbe
    record = model.create!(amount: BigDecimal('123456789012345.12345678'), payload: { 'large' => 9_223_372_036_854_775_807 },
                           indexed_payload: { 'enabled' => true, 'items' => [nil, 'é'] },
                           instant: Time.iso8601('2026-11-01T01:30:00-04:00'), day: Date.new(2026, 11, 1), bytes: "\x00\x7f\xff".b)
    record.reload
    assert_equal BigDecimal('123456789012345.12345678'), record.amount
    assert_equal 9_223_372_036_854_775_807, record.payload['large']
    assert_equal [nil, 'é'], record.indexed_payload['items']
    assert_equal Time.utc(2026, 11, 1, 5, 30), record.instant
    assert_equal Date.new(2026, 11, 1), record.day
    assert_equal "\x00\x7f\xff".b, record.bytes
    assert_equal 1, model.where('indexed_payload @> ?', { enabled: true }.to_json).count
    assert_equal true, @connection.select_value("SELECT indisvalid FROM pg_index WHERE indexrelid='pg_compatibility_json_idx'::regclass")
    second = model.create!(amount: BigDecimal('-0.00000001'))
    assert_operator second.id, :>, record.id
    assert_equal BigDecimal('-0.00000001'), second.reload.amount
  end

  def test_delivered_schema_tools_replay_the_schema
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    file = Tempfile.new(['pg-compatibility', '.sql'])
    target_name = "fm_pg_a_replay_#{SecureRandom.hex(8)}"
    maintenance = PG.connect(**connection_options.merge(dbname: 'postgres'))
    maintenance.exec("CREATE DATABASE #{PG::Connection.quote_ident(target_name)}")
    created = true
    tasks = ActiveRecord::Tasks::PostgreSQLDatabaseTasks
    tasks.new(ActiveRecord::Base.connection_db_config).structure_dump(file.path, [])
    tasks.new(ActiveRecord::DatabaseConfigurations::HashConfig.new('test', 'replay', config.merge(database: target_name))).structure_load(
      file.path, []
    )
    PG.connect(**connection_options.merge(dbname: target_name)) do |target|
      tables = target.exec("SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename").values.flatten
      assert_equal @connection.tables.sort, tables
      assert_equal 'cafe', target.exec("SELECT public.f_unaccent('café')").getvalue(0, 0)
      count = target.exec("SELECT count(*) FROM pg_class WHERE relkind='S' AND relnamespace='public'::regnamespace").getvalue(0, 0).to_i
      assert_equal @connection.select_value("SELECT count(*) FROM pg_class WHERE relkind='S' AND relnamespace='public'::regnamespace"), count
    end
  ensure
    maintenance&.exec("DROP DATABASE #{PG::Connection.quote_ident(target_name)}") if created
    maintenance&.close
    file&.close!
  end
end

# Run the actual application endpoints on newly seeded data with no historical fixture chains.
class PostgreSQLApplicationCompatibilityTest < PostgreSQLCompatibilityCase
  def test_project_search_uses_the_installed_extensions_and_trigger
    project = Project.create!(name: 'Atelier éléphant', description: 'Un café à Québec',
                              author: User.admins.first.statistic_profile, licence: Licence.first, status: Status.first)
    assert_includes Project.search('cafe').pluck(:id), project.id
    assert_includes Project.search('eleph').pluck(:id), project.id
    assert_includes Project.search('quebec').pluck(:id), project.id
    assert_equal false, Project.search('zzzznotfound').exists?(id: project.id)
    index_names = @connection.indexes(:projects).map(&:name)
    assert_includes index_names, 'projects_search_vector_idx'
  end

  def test_admin_authenticates_and_reads_seeded_catalogue
    session.post '/users/sign_in', params: { user: { email: ENV.fetch('ADMIN_EMAIL'), password: ENV.fetch('ADMIN_PASSWORD') } }.to_json,
                                   headers: json_headers
    assert_equal 201, session.response.status
    session.get '/api/trainings', headers: json_headers
    assert_equal 200, session.response.status
    assert_operator JSON.parse(session.response.body).size, :>, 0
  end

  def test_local_reservation_invoice_and_jsonb_place_cache
    admin = User.admins.first
    user = create_member
    training, availability = prepare_training(user)
    session.post '/users/sign_in', params: { user: { email: admin.email, password: ENV.fetch('ADMIN_PASSWORD') } }.to_json,
                                   headers: json_headers
    assert_equal 201, session.response.status
    before = [Reservation.count, Invoice.count, InvoiceItem.count]
    session.post '/api/local_payment/confirm_payment', params: {
      customer_id: user.id, items: [{ reservation: { reservable_id: training.id, reservable_type: 'Training',
                                                     slots_reservations_attributes: [{ slot_id: availability.slots.first.id }] } }]
    }.to_json, headers: json_headers
    assert_equal 201, session.response.status, session.response.body
    assert_equal before.map { |count| count + 1 }, [Reservation.count, Invoice.count, InvoiceItem.count]
    assert_booking_data(user, training, availability)
  end

  private

  def prepare_training(user)
    training = Training.first
    pricing = TrainingsPricing.find_by!(training_id: training.id, group_id: user.group_id)
    pricing.update!(amount: 1500)
    starts = 3.days.from_now.change(hour: 10, min: 0)
    availability = Availability.create!(available_type: 'training', training_ids: [training.id],
                                        start_at: starts, end_at: starts + 2.hours, nb_total_places: 6)
    Availabilities::CreateAvailabilitiesService.new.create(availability, [])
    availability.reload
    [training, availability]
  end

  def create_member
    Setting.set('online_payment_module', false)
    User.create!(username: "pgcompat#{SecureRandom.hex(6)}", email: "pgcompat-#{SecureRandom.hex(6)}@example.test",
                 password: 'Synthetic!Password42', password_confirmation: 'Synthetic!Password42', cgu: true,
                 group: Group.first, confirmed_at: Time.current,
                 profile_attributes: { first_name: 'Synthetic', last_name: 'Member', phone: '0123456789' },
                 statistic_profile_attributes: { gender: true, birthday: Date.new(1990, 1, 1) })
  end

  def assert_booking_data(user, training, availability)
    invoice = Reservation.last.original_invoice
    assert_equal 1500, invoice.total
    assert invoice.check_footprint
    assert InvoiceItem.last.check_footprint
    assert_equal user.invoicing_profile.id, invoice.invoicing_profile_id
    place = availability.slots.first.reload.places.find { |item| item['reservable_id'] == training.id }
    assert_equal 1, place['reserved_places']
    assert_includes place['user_ids'], user.id
    session.get "/api/invoices/#{invoice.id}", headers: json_headers
    assert_equal 200, session.response.status
    session.get '/api/availabilities', params: { start: availability.start_at.iso8601, end: availability.end_at.iso8601,
                                                 timezone: 'America/Toronto' }, headers: json_headers
    assert_equal 200, session.response.status
  end
end

# The command-line archive tools are tested independently of the driver's libpq.
class PostgreSQLArchiveCompatibilityTest < PostgreSQLCompatibilityCase
  def test_archive_created_from_each_server_restores_on_target
    archive = Tempfile.new(['pg-compatibility', '.dump'])
    environment = { 'PGHOST' => ENV.fetch('POSTGRES_HOST'), 'PGUSER' => ENV.fetch('POSTGRES_USERNAME'),
                    'PGPASSWORD' => ENV.fetch('POSTGRES_PASSWORD') }
    _, error, status = Open3.capture3(environment, 'pg_dump', '--schema-only', '--format=custom',
                                      '--file', archive.path, @connection.current_database)
    assert status.success?, error
    listing, error, status = Open3.capture3('pg_restore', '--list', archive.path)
    assert status.success?, error
    assert_includes listing, 'TABLE public users'
    target_name = "fm_pg_a_archive_#{SecureRandom.hex(8)}"
    maintenance = PG.connect(**connection_options.merge(host: 'pg18', dbname: 'postgres'))
    maintenance.exec("CREATE DATABASE #{PG::Connection.quote_ident(target_name)}")
    created = true
    _, error, status = Open3.capture3(environment.merge('PGHOST' => 'pg18'), 'pg_restore', '--exit-on-error',
                                      '--single-transaction', '--no-owner', '--no-acl', '--dbname', target_name, archive.path)
    assert status.success?, error
    PG.connect(**connection_options.merge(host: 'pg18', dbname: target_name)) do |target|
      assert_equal 'cafe', target.exec("SELECT public.f_unaccent('café')").getvalue(0, 0)
      tables = target.exec("SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename").values.flatten
      assert_equal @connection.tables.sort, tables
    end
  ensure
    maintenance&.exec("DROP DATABASE #{PG::Connection.quote_ident(target_name)}") if created
    maintenance&.close
    archive&.close!
  end
end
