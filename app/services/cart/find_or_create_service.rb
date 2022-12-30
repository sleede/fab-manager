# frozen_string_literal: true

# Provides methods for find or create a cart
class Cart::FindOrCreateService
  def initialize(operator = nil, customer = nil)
    @operator = operator
    @customer = customer
    @customer = operator if @customer.nil? && operator&.member?
  end

  def call(order_token)
    @order = Order.find_by(token: order_token, state: 'cart')
    check_order_authorization
    @order = last_cart if @order.nil?
    check_operator_authorization

    # find an existing order (and update it)
    if @order
      set_last_order_after_login
      clean_old_cart
      @order.update(statistic_profile_id: @customer.statistic_profile.id) if @order.statistic_profile_id.nil? && !@customer.nil?
      @order.update(operator_profile_id: @operator.invoicing_profile.id) if @order.operator_profile_id.nil? && !@operator.nil?
      Cart::UpdateTotalService.new.call(@order)
      return @order
    end

    # OR create a new order
    token = GenerateTokenService.new.call(Order)
    order_param = {
      token: token,
      state: 'cart',
      total: 0,
      statistic_profile_id: @customer&.statistic_profile&.id,
      operator_profile_id: @operator&.invoicing_profile&.id
    }
    Order.create!(order_param)
  end

  # This function check the access rights for the currently set order.
  # If the rights are not validated, set the current order to nil
  def check_order_authorization
    # order belongs to the current user
    @order = nil if belongs_to_another?(@order, @customer) && !@operator&.privileged?
    # order has belonged to an user, but this user is not logged-in
    @order = nil if !@operator && @order&.statistic_profile_id&.present?
    # order creation date is before than the last paid order of the user
    if @order&.statistic_profile_id&.present? && Order.where(statistic_profile_id: @order&.statistic_profile_id, state: 'paid')
                                                      .where('created_at > ?', @order&.created_at).last.present?
      @order = nil
    end
  end

  # Check that the current operator is allowed to operate on the current order
  def check_operator_authorization
    return if @order&.operator_profile_id.nil?

    @order = nil if @order&.operator_profile_id != @operator&.invoicing_profile&.id
  end

  def belongs_to_another?(order, user)
    order&.statistic_profile_id.present? && order&.statistic_profile_id != user&.statistic_profile&.id
  end

  # retrieve the last cart of the current user
  def last_cart
    return if @customer.nil?

    last_paid_order = Order.where(statistic_profile_id: @customer&.statistic_profile&.id, state: 'paid')
                           .last
    if last_paid_order
      Order.where(statistic_profile_id: @customer&.statistic_profile&.id, state: 'cart')
           .where('created_at > ?', last_paid_order.created_at)
           .last
    else
      Order.where(statistic_profile_id: @customer&.statistic_profile&.id, state: 'cart')
           .last
    end
  end

  # Check if the provided order/cart is empty AND anonymous
  def empty_and_anonymous?(order)
    order&.order_items&.count&.zero? && (order&.operator_profile_id.nil? || order&.statistic_profile_id.nil?)
  end

  # If the current cart is empty and anonymous, set the current cart as the last unpaid order.
  # This is relevant after the user has logged-in
  def set_last_order_after_login
    return unless empty_and_anonymous?(@order)

    last_unpaid_order = last_cart
    return if last_unpaid_order.nil? || last_unpaid_order.id == @order&.id

    @order&.destroy
    @order = last_unpaid_order
  end

  # delete all old cart if last cart of user isnt empty
  # keep every user only one cart
  def clean_old_cart
    return if @customer.nil?

    Order.where(statistic_profile_id: @customer&.statistic_profile&.id, state: 'cart')
         .where.not(id: @order&.id)
         .destroy_all
  end
end
