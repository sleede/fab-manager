# frozen_string_literal: true

# Run only against the synthetic migration database; no historical fixture chains are regenerated.
raise 'Synthetic migration database required' unless ActiveRecord::Base.connection.current_database.start_with?('fm_pg_b_')

require 'json'
require 'digest'
require 'csv'
require 'pdf/reader'
require 'minitest/assertions'
require 'active_support/testing/time_helpers'
require 'sidekiq/testing'

class PostgreSQLMigrationWorkload
  include Minitest::Assertions
  include ActiveSupport::Testing::TimeHelpers
  attr_accessor :assertions

  PASSWORD = 'Synthetic!Migration42'

  def initialize
    self.assertions = 0
    @connection = ActiveRecord::Base.connection
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }
    @session = ActionDispatch::Integration::Session.new(Rails.application)
    raise 'External mail must remain disabled' unless ActionMailer::Base.delivery_method == :test
  end

  def request(method, path, params = nil, status: 200)
    @session.public_send(method, path, params: params&.to_json, headers: @headers)
    assert_equal status, @session.response.status, "#{method} #{path}: #{@session.response.body[0, 600]}"
    return {} if @session.response.body.empty?

    return { 'raw_body' => @session.response.body } unless @session.response.media_type == 'application/json'

    JSON.parse(@session.response.body)
  end

  def login(user = User.admins.first)
    request(:post, '/users/sign_in', { user: { email: user.email, password: PASSWORD } }, status: 201)
  end

  def member(index)
    User.create!(username: "migration-member-#{index}", email: "migration-member-#{index}@example.test",
                 password: PASSWORD, password_confirmation: PASSWORD, cgu: true,
                 group: Group.order(:id)[index % Group.count], confirmed_at: Time.current,
                 profile_attributes: { first_name: "Amélie#{index}", last_name: 'Québec', phone: '0123456789' },
                 statistic_profile_attributes: { gender: index.even?, birthday: Date.new(1980 + index, 2, 2) })
  end

  def reservation(user, index)
    training = Training.order(:id)[index % Training.count]
    TrainingsPricing.find_by!(training_id: training.id, group_id: user.group_id).update!(amount: 1501 + index)
    starts = Time.iso8601(index.even? ? '2026-11-01T01:30:00-04:00' : '2026-11-01T01:30:00-05:00')
    availability = Availability.create!(available_type: 'training', training_ids: [training.id],
                                        start_at: starts, end_at: starts + 2.hours, nb_total_places: 6)
    Availabilities::CreateAvailabilitiesService.new.create(availability, [])
    invoice = request(:post, '/api/local_payment/confirm_payment',
                      { customer_id: user.id, items: [{ reservation: {
                        reservable_id: training.id, reservable_type: 'Training',
                        slots_reservations_attributes: [{ slot_id: availability.reload.slots.first.id }]
                      } }] }, status: 201)
    record = Invoice.find(invoice.fetch('id'))
    assert_equal 1501 + index, record.total
    assert record.check_footprint
    record
  end

  def purchase(user)
    plan = Plan.create!(group: user.group, base_name: 'Abonnement mensuel Québec', type: 'Plan',
                        amount: 12_345, interval: 'month', interval_count: 1)
    request(:post, '/api/local_payment/confirm_payment',
            { customer_id: user.id, items: [{ subscription: { plan_id: plan.id } }] }, status: 201)
    assert_equal plan.id, user.reload.subscription.plan_id
  end

  def shop(user)
    category = ProductCategory.find_or_create_by!(name: 'Pièces électriques')
    product = Product.find_by(name: 'Écrou précision') || Product.create!(name: 'Écrou précision', product_category: category, is_active: true,
                                                                          amount: 2345, quantity_min: 1, stock: { external: 20, internal: 0 })
    if product.product_stock_movements.empty?
      product.product_stock_movements.create!(stock_type: 'external', reason: 'inward_stock',
                                              quantity: 20)
    end
    order = Cart::FindOrCreateService.new(User.admins.first, user).call(nil)
    Cart::AddItemService.new.call(order, product, 3)
    request(:post, '/api/checkout/payment', { order_token: order.token, customer_id: user.id })
    assert_equal 'paid', order.reload.state
    assert_equal 7035, order.paid_total
    assert order.invoice.check_footprint
  end

  def export
    result = request(:post, '/api/accounting/export', {
                       query: { columns: %w[journal_code date account_code account_label piece line_label debit_origin credit_origin
                                            debit_euro credit_euro lettering], encoding: 'UTF-8', date_format: '%d/%m/%Y',
                                start_date: '2026-01-01T00:00:00Z', end_date: '2026-12-31T23:59:59Z', label_max_length: 50,
                                decimal_separator: ',', export_invoices_at_zero: true }.to_json,
                       extension: 'csv', type: 'acd', key: ';'
                     })
    record = result['export_id'] ? Export.find(result['export_id']) : Export.where(category: 'accounting').order(:id).last
    AccountingExportWorker.new.perform(record.id)
    assert File.exist?(record.file)
    rows = CSV.read(record.file, headers: true, col_sep: ';')
    assert_operator rows.length, :>, 0
    rows.length
  end

  def provision
    raise 'Refusing to overwrite an existing workload' if User.exists?(username: 'migration-member-0')

    Sidekiq::Testing.fake!
    travel_to(Time.zone.parse('2026-10-24 12:00:00')) do
      members = prepare_catalogue
      invoices = 2.times.map { |index| reservation(members[index], index) }
      purchase(members[2])
      shop(members[0])
      refund_and_cancel(invoices.first, invoices.last)
      assert_equal 1, Avoir.count
      render_invoices
      finish_provision

      check
    end
    check
  ensure
    travel_back
  end

  def finish_provision
    @session = ActionDispatch::Integration::Session.new(Rails.application)
    login
    AccountingWorker.new.perform('all')
    export
    @connection.execute('CREATE TABLE migration_worker_probes (id bigserial PRIMARY KEY, run_id text UNIQUE NOT NULL, ' \
                        'database_version integer NOT NULL, users_count integer NOT NULL, invoice_cents bigint NOT NULL, ' \
                        'created_at timestamptz DEFAULT CURRENT_TIMESTAMP)')
    @connection.execute('CREATE SEQUENCE migration_nontrivial_seq START 1001 INCREMENT 7 CACHE 3')
    @connection.execute("SELECT setval('users_id_seq', (SELECT max(id)+1000 FROM users), false)")
    @connection.execute("SELECT setval('invoices_id_seq', (SELECT max(id)+500 FROM invoices), false)")
    check
  end

  def check(after_writes: false)
    @connection.transaction do
      @connection.execute('SET TRANSACTION READ ONLY')
      verify_footprints
      verify_relations(after_writes: after_writes)
      instants = Availability.order(:start_at).pluck(:start_at).map(&:iso8601)
      { members: User.count, profiles: Profile.count, groups: Group.count, projects: Project.count,
        reservations: Reservation.count, subscriptions: Subscription.count, orders: Order.count, invoices: Invoice.count,
        cents: Invoice.sum(:total), financial_sha256: financial_identity_hash, instants: instants }
    end
  end

  def journeys
    read_existing_documents
    new_member = member(21)
    assert_operator new_member.id, :>, User.where.not(id: new_member.id).maximum(:id)
    travel_to(Time.zone.parse('2026-10-24 12:00:00')) do
      created_invoice = reservation(new_member, 2)
      refund_and_cancel(created_invoice, created_invoice)
      purchase(new_member)
      shop(new_member)
    end
    render_invoices
    AccountingWorker.new.perform('all')
    export
    verify_footprints
    { assertions: assertions, existing_invoices: Invoice.count, new_member: new_member.id }
  ensure
    travel_back
  end

  def prepare_catalogue
    Setting.set('online_payment_module', false)
    Setting.set('fab_analytics', false)
    Setting.set('openlab_app_secret', nil)
    Setting.set('booking_cancel_enable', true)
    Setting.set('booking_cancel_delay', 24)
    members = 20.times.map { |index| member(index) }
    login
    30.times do |index|
      Project.create!(name: "Atelier éléphant #{index}", description: "Café à Québec — été #{index}",
                      author: members[index % members.size].statistic_profile, licence: Licence.first, status: Status.first)
    end
    members
  end

  def refund_and_cancel(invoice, canceled_invoice)
    request(:post, '/api/invoices', { avoir: { invoice_id: invoice.id,
                                               invoice_items_ids: invoice.invoice_items.pluck(:id), payment_method: 'cash',
                                               description: 'Remboursement synthétique', subscription_to_expire: false } }, status: 201)
    slot = canceled_invoice.main_item.object.slots_reservations.first
    request(:put, "/api/slots_reservations/#{slot.id}/cancel")
    assert slot.reload.canceled_at
  end

  def render_invoices
    Invoice.find_each do |invoice|
      InvoiceWorker.new.perform(invoice.id)
      assert File.exist?(invoice.file)
      assert_operator PDF::Reader.new(invoice.file).page_count, :>, 0
    end
  end

  def read_existing_documents
    login
    member = User.find_by!(username: 'migration-member-0')
    @session = ActionDispatch::Integration::Session.new(Rails.application)
    login(member)
    request(:get, '/api/trainings')
    @session = ActionDispatch::Integration::Session.new(Rails.application)
    login
    invoice = Invoice.only_invoice.order(:id).first
    request(:get, "/api/invoices/#{invoice.id}")
    @session.get "/api/invoices/#{invoice.id}/download"
    assert_equal 200, @session.response.status
    assert_equal 'application/pdf', @session.response.media_type
    request(:get, '/api/availabilities?start=2026-10-01&end=2026-12-01&timezone=America%2FToronto')
    export
  end

  def verify_footprints
    [Invoice, InvoiceItem, HistoryValue, PaymentSchedule, PaymentScheduleItem, PaymentScheduleObject].each do |model|
      model.find_each { |record| assert record.check_footprint, "#{model} #{record.id}: invalid footprint" }
    end
  end

  def verify_relations(after_writes: false)
    assert_equal(after_writes ? 21 : 20, User.where("username LIKE 'migration-member-%'").count)
    assert_equal 30, Project.where("name LIKE 'Atelier éléphant%'").count
    assert_operator Project.search('quebec').count, :>=, 30
    assert_operator Reservation.count, :>=, 2
    assert_operator Subscription.count, :>=, 1
    assert_operator Order.paid.count, :>=, 1
    assert_equal(after_writes ? 2 : 1, Avoir.count)
  end

  def financial_identity_hash
    financial = Invoice.order(:id).map do |invoice|
      [invoice.id, invoice.class.name, invoice.reference, invoice.total, invoice.invoicing_profile_id,
       invoice.invoice_items.order(:id).pluck(:id, :amount), invoice.chained_element.footprint]
    end
    Digest::SHA256.hexdigest(JSON.generate(financial))
  end
end

workload = PostgreSQLMigrationWorkload.new
action = ENV.fetch('FM_MIGRATION_ACTION', 'check')
result = action == 'check_after_writes' ? workload.check(after_writes: true) : workload.public_send(action)
puts "FM_WORKLOAD_RESULT=#{JSON.generate(result)}"
