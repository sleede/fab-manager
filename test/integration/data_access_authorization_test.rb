# frozen_string_literal: true

require 'test_helper'

class DataAccessAuthorizationTest < ActionDispatch::IntegrationTest
  def setup
    Warden.test_reset!
    @admin = User.find_by(username: 'admin')
    @user_a = User.find(7)
    @user_b = User.find(8)
    @manager = User.where.not(id: [@admin.id, @user_a.id, @user_b.id]).first
    @manager.roles << Role.find_or_create_by!(name: 'manager') unless @manager.has_role?(:manager)

    @invoice = @user_a.invoicing_profile.invoices.first
    @order = Order.where(statistic_profile_id: @user_a.statistic_profile.id).first
    @reservation = @user_a.statistic_profile.reservations.first
    @doc = SupportingDocumentFile.create!(
      supportable: @user_a,
      supporting_document_type: SupportingDocumentType.first,
      attachment: File.open(Rails.root.join('test/fixtures/files/document.pdf'))
    )
    @accounting_period = AccountingPeriod.first || AccountingPeriod.create!(
      start_at: '2015-01-01',
      end_at: '2015-12-31',
      closed_at: Time.current,
      closed_by: @admin.id,
      period_total: 1500,
      perpetual_total: 4500
    )
  end

  def teardown
    @doc&.destroy if @doc&.persisted?
    Warden.test_reset!
  end

  # ==========================================
  # INVOICES
  # ==========================================
  test 'unauthenticated visitor cannot access invoice' do
    get "/api/invoices/#{@invoice.id}", headers: default_headers
    assert_response :unauthorized
  end

  test 'invoice owner can access own invoice' do
    login_as(@user_a, scope: :user)
    get "/api/invoices/#{@invoice.id}", headers: default_headers
    assert_response :ok
    assert_equal @invoice.id, json_response(response.body)[:id]
  end

  test 'unrelated member cannot access other member invoice' do
    login_as(@user_b, scope: :user)
    get "/api/invoices/#{@invoice.id}", headers: default_headers
    assert_response :forbidden
  end

  test 'manager can access member invoice' do
    login_as(@manager, scope: :user)
    get "/api/invoices/#{@invoice.id}", headers: default_headers
    assert_response :ok
    assert_equal @invoice.id, json_response(response.body)[:id]
  end

  test 'admin can access member invoice' do
    login_as(@admin, scope: :user)
    get "/api/invoices/#{@invoice.id}", headers: default_headers
    assert_response :ok
    assert_equal @invoice.id, json_response(response.body)[:id]
  end

  # ==========================================
  # ORDERS
  # ==========================================
  test 'unauthenticated visitor cannot access order' do
    get "/api/orders/#{@order.id}", headers: default_headers
    assert_response :unauthorized
  end

  test 'order owner can access own order' do
    login_as(@user_a, scope: :user)
    get "/api/orders/#{@order.id}", headers: default_headers
    assert_response :ok
    assert_equal @order.id, json_response(response.body)[:id]
  end

  test 'unrelated member cannot access other member order' do
    login_as(@user_b, scope: :user)
    get "/api/orders/#{@order.id}", headers: default_headers
    assert_response :forbidden
  end

  test 'manager can access member order' do
    login_as(@manager, scope: :user)
    get "/api/orders/#{@order.id}", headers: default_headers
    assert_response :ok
    assert_equal @order.id, json_response(response.body)[:id]
  end

  test 'admin can access member order' do
    login_as(@admin, scope: :user)
    get "/api/orders/#{@order.id}", headers: default_headers
    assert_response :ok
    assert_equal @order.id, json_response(response.body)[:id]
  end

  test 'profileless member cannot access ownerless order' do
    ownerless_order = Order.create!(token: SecureRandom.hex(16), state: 'paid', total: 10)
    user = User.create!(
      username: 'profileless1',
      email: 'profileless1@fab-manager.com',
      password: 'Password123!',
      password_confirmation: 'Password123!',
      group_id: 1,
      cgu: true,
      profile_attributes: { first_name: 'Profile', last_name: 'Less' }
    )
    user.statistic_profile&.destroy
    user.reload

    login_as(user, scope: :user)
    get "/api/orders/#{ownerless_order.id}", headers: default_headers
    assert_response :forbidden
  ensure
    ownerless_order&.destroy
    if user
      user.create_statistic_profile(group: user.group, role_id: user.roles.first&.id) if user.statistic_profile.nil?
      user.destroy
    end
  end

  test 'profileless member cannot access withdrawal instructions for ownerless order' do
    ownerless_order = Order.create!(token: SecureRandom.hex(16), state: 'paid', total: 10)
    user = User.create!(
      username: 'profileless2',
      email: 'profileless2@fab-manager.com',
      password: 'Password123!',
      password_confirmation: 'Password123!',
      group_id: 1,
      cgu: true,
      profile_attributes: { first_name: 'Profile', last_name: 'Less' }
    )
    user.statistic_profile&.destroy
    user.reload

    login_as(user, scope: :user)
    get "/api/orders/#{ownerless_order.id}/withdrawal_instructions", headers: default_headers
    assert_response :forbidden
  ensure
    ownerless_order&.destroy
    if user
      user.create_statistic_profile(group: user.group, role_id: user.roles.first&.id) if user.statistic_profile.nil?
      user.destroy
    end
  end

  test 'unauthenticated visitor cannot access withdrawal instructions for ownerless order' do
    ownerless_order = Order.create!(token: SecureRandom.hex(16), state: 'paid', total: 10)
    get "/api/orders/#{ownerless_order.id}/withdrawal_instructions", headers: default_headers
    assert_response :forbidden
  ensure
    ownerless_order&.destroy
  end

  test 'unauthenticated visitor can access withdrawal instructions for cart order' do
    cart_order = Order.create!(token: SecureRandom.hex(16), state: 'cart', total: 10)
    get "/api/orders/#{cart_order.id}/withdrawal_instructions", headers: default_headers
    assert_response :ok
  ensure
    cart_order&.destroy
  end

  test 'partner user cannot access other users orders in index' do
    partner = User.find_by(username: 'partner') || User.find(6)
    login_as(partner, scope: :user)
    get '/api/orders', headers: default_headers
    assert_response :ok
    returned_orders = json_response(response.body)[:data]
    assert returned_orders.none? { |o| o[:statistic_profile_id] != partner.statistic_profile&.id }

    # Even when explicitly filtering by another user_id
    get "/api/orders?user_id=#{@user_a.id}", headers: default_headers
    assert_response :ok
    filtered_orders = json_response(response.body)[:data]
    assert filtered_orders.none? { |o| o[:statistic_profile_id] == @user_a.statistic_profile.id }
  end

  test 'profileless user cannot access ownerless orders in index even with user_id parameter' do
    ownerless_order = Order.create!(token: SecureRandom.hex(16), state: 'paid', total: 10)
    user = User.create!(
      username: 'profileless3',
      email: 'profileless3@fab-manager.com',
      password: 'Password123!',
      password_confirmation: 'Password123!',
      group_id: 1,
      cgu: true,
      profile_attributes: { first_name: 'Profile', last_name: 'Less' }
    )
    user.statistic_profile&.destroy
    user.reload

    login_as(user, scope: :user)
    get '/api/orders', headers: default_headers
    assert_response :ok
    assert_equal 0, json_response(response.body)[:data].size

    get "/api/orders?user_id=#{user.id}", headers: default_headers
    assert_response :ok
    assert_equal 0, json_response(response.body)[:data].size

    get "/api/orders?user_id=#{@user_a.id}", headers: default_headers
    assert_response :ok
    assert_equal 0, json_response(response.body)[:data].size
  ensure
    ownerless_order&.destroy
    if user
      user.create_statistic_profile(group: user.group, role_id: user.roles.first&.id) if user.statistic_profile.nil?
      user.destroy
    end
  end

  test 'cart withdrawal instructions never leak private ready note' do
    cart_order = Order.create!(token: SecureRandom.hex(16), state: 'cart', total: 10)
    cart_order.order_activities.create!(activity_type: 'ready', note: 'SUPER_SECRET_READY_NOTE_XYZ')

    get "/api/orders/#{cart_order.id}/withdrawal_instructions", headers: default_headers
    assert_response :ok
    refute_includes response.body, 'SUPER_SECRET_READY_NOTE_XYZ'
  ensure
    cart_order&.destroy
  end

  # ==========================================
  # RESERVATIONS
  # ==========================================
  test 'unauthenticated visitor cannot access reservation' do
    get "/api/reservations/#{@reservation.id}", headers: default_headers
    assert_response :unauthorized
  end

  test 'reservation owner can access own reservation' do
    login_as(@user_a, scope: :user)
    get "/api/reservations/#{@reservation.id}", headers: default_headers
    assert_response :ok
    assert_equal @reservation.id, json_response(response.body)[:id]
  end

  test 'unrelated member cannot access other member reservation' do
    login_as(@user_b, scope: :user)
    get "/api/reservations/#{@reservation.id}", headers: default_headers
    assert_response :forbidden
  end

  test 'manager can access member reservation' do
    login_as(@manager, scope: :user)
    get "/api/reservations/#{@reservation.id}", headers: default_headers
    assert_response :ok
    assert_equal @reservation.id, json_response(response.body)[:id]
  end

  test 'admin can access member reservation' do
    login_as(@admin, scope: :user)
    get "/api/reservations/#{@reservation.id}", headers: default_headers
    assert_response :ok
    assert_equal @reservation.id, json_response(response.body)[:id]
  end

  # ==========================================
  # SUPPORTING DOCUMENT FILES
  # ==========================================
  test 'unauthenticated visitor cannot access supporting document file' do
    get "/api/supporting_document_files/#{@doc.id}", headers: default_headers
    assert_response :unauthorized
  end

  test 'document owner can access own supporting document file' do
    login_as(@user_a, scope: :user)
    get "/api/supporting_document_files/#{@doc.id}", headers: default_headers
    assert_response :ok
    assert_equal @doc.id, json_response(response.body)[:id]
  end

  test 'unrelated member cannot access other member supporting document file' do
    login_as(@user_b, scope: :user)
    get "/api/supporting_document_files/#{@doc.id}", headers: default_headers
    assert_response :forbidden
  end

  test 'manager can access member supporting document file' do
    login_as(@manager, scope: :user)
    get "/api/supporting_document_files/#{@doc.id}", headers: default_headers
    assert_response :ok
    assert_equal @doc.id, json_response(response.body)[:id]
  end

  test 'admin can access member supporting document file' do
    login_as(@admin, scope: :user)
    get "/api/supporting_document_files/#{@doc.id}", headers: default_headers
    assert_response :ok
    assert_equal @doc.id, json_response(response.body)[:id]
  end

  # ==========================================
  # ACCOUNTING PERIODS
  # ==========================================
  test 'unauthenticated visitor cannot access accounting periods index or show' do
    get '/api/accounting_periods', headers: default_headers
    assert_response :unauthorized

    get "/api/accounting_periods/#{@accounting_period.id}", headers: default_headers
    assert_response :unauthorized
  end

  test 'regular member cannot access accounting periods index or show' do
    login_as(@user_a, scope: :user)
    get '/api/accounting_periods', headers: default_headers
    assert_response :forbidden

    get "/api/accounting_periods/#{@accounting_period.id}", headers: default_headers
    assert_response :forbidden
  end

  test 'manager cannot access accounting periods index or show' do
    login_as(@manager, scope: :user)
    get '/api/accounting_periods', headers: default_headers
    assert_response :forbidden

    get "/api/accounting_periods/#{@accounting_period.id}", headers: default_headers
    assert_response :forbidden
  end

  test 'admin can access accounting periods index and show' do
    login_as(@admin, scope: :user)
    get '/api/accounting_periods', headers: default_headers
    assert_response :ok

    get "/api/accounting_periods/#{@accounting_period.id}", headers: default_headers
    assert_response :ok
    assert_equal @accounting_period.id, json_response(response.body)[:id]
  end
end
