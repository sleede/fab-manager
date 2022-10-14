# frozen_string_literal: true

# Provides methods for find or create a cart
class Cart::FindOrCreateService
  def initialize(user)
    @user = user
  end

  def call(order_token)
    @order = Order.find_by(token: order_token, state: 'cart')
    check_order_authorization
    set_last_cart_if_user_login if @order.nil?

    if @order
      if @order.order_items.count.zero? && @user && ((@user.member? && @order.statistic_profile_id.nil?) || (@user.privileged? && @order.operator_profile_id.nil?))
        set_last_order_if_anonymous_order_s_items_is_empty_after_user_login
      end
      clean_old_cart if @user
      @order.update(statistic_profile_id: @user.statistic_profile.id) if @order.statistic_profile_id.nil? && @user&.member?
      @order.update(operator_profile_id: @user.invoicing_profile.id) if @order.operator_profile_id.nil? && @user&.privileged?
      Cart::UpdateTotalService.new.call(@order)
      return @order
    end

    token = GenerateTokenService.new.call(Order)
    order_param = {
      token: token,
      state: 'cart',
      total: 0
    }
    if @user
      order_param[:statistic_profile_id] = @user.statistic_profile.id if @user.member?

      order_param[:operator_profile_id] = @user.invoicing_profile.id if @user.privileged?
    end
    Order.create!(order_param)
  end

  # This function check current order that
  # 1. belongs current user
  # 2. has belonged an user but this user dont login
  # 3. created date > last paid order of user
  # if not, set current order = nil
  def check_order_authorization
    if @order && @user && ((@user.member? && @order.statistic_profile_id.present? && @order.statistic_profile_id != @user.statistic_profile.id) ||
        (@user.privileged? && @order.operator_profile_id.present? && @order.operator_profile_id != @user.invoicing_profile.id))
      @order = nil
    end
    @order = nil if @order && !@user && (@order.statistic_profile_id.present? || @order.operator_profile_id.present?)
    if @order && @order.statistic_profile_id.present? && Order.where(statistic_profile_id: @order.statistic_profile_id,
                                                                     state: 'paid').where('created_at > ?', @order.created_at).last.present?
      @order = nil
    end
    if @order && @order.operator_profile_id.present? && Order.where(operator_profile_id: @order.operator_profile_id,
                                                                    state: 'paid').where('created_at > ?', @order.created_at).last.present?
      @order = nil
    end
  end

  # set user last cart of user when login
  def set_last_cart_if_user_login
    if @user&.member?
      last_paid_order = Order.where(statistic_profile_id: @user.statistic_profile.id,
                                    state: 'paid').last
      @order = if last_paid_order
                 Order.where(statistic_profile_id: @user.statistic_profile.id,
                             state: 'cart').where('created_at > ?', last_paid_order.created_at).last
               else
                 Order.where(statistic_profile_id: @user.statistic_profile.id, state: 'cart').last
               end
    end
    if @user&.privileged?
      last_paid_order = Order.where(operator_profile_id: @user.invoicing_profile.id,
                                    state: 'paid').last
      @order = if last_paid_order
                 Order.where(operator_profile_id: @user.invoicing_profile.id,
                             state: 'cart').where('created_at > ?', last_paid_order.created_at).last
               else
                 Order.where(operator_profile_id: @user.invoicing_profile.id, state: 'cart').last
               end
    end
  end

  # set last order if current cart is anoymous and user is login
  def set_last_order_if_anonymous_order_s_items_is_empty_after_user_login
    last_unpaid_order = nil
    if @user&.member?
      last_paid_order = Order.where(statistic_profile_id: @user.statistic_profile.id,
                                    state: 'paid').last
      last_unpaid_order = if last_paid_order
                            Order.where(statistic_profile_id: @user.statistic_profile.id,
                                        state: 'cart').where('created_at > ?', last_paid_order.created_at).last
                          else
                            Order.where(statistic_profile_id: @user.statistic_profile.id, state: 'cart').last
                          end
    end
    if @user&.privileged?
      last_paid_order = Order.where(operator_profile_id: @user.invoicing_profile.id,
                                    state: 'paid').last
      last_unpaid_order = if last_paid_order
                            Order.where(operator_profile_id: @user.invoicing_profile.id,
                                        state: 'cart').where('created_at > ?', last_paid_order.created_at).last
                          else
                            Order.where(operator_profile_id: @user.invoicing_profile.id, state: 'cart').last
                          end
    end
    if last_unpaid_order && last_unpaid_order.id != @order.id
      @order.destroy
      @order = last_unpaid_order
    end
  end

  # delete all old cart if last cart of user isnt empty
  # keep every user only one cart
  def clean_old_cart
    if @user&.member?
      Order.where(statistic_profile_id: @user.statistic_profile.id, state: 'cart')
           .where.not(id: @order.id)
           .destroy_all
    end
    if @user&.privileged?
      Order.where(operator_profile_id: @user.invoicing_profile.id, state: 'cart')
           .where.not(id: @order.id)
           .destroy_all
    end
  end

  # delete all empty cart if last cart of user isnt empty
  def clean_empty_cart
    if @user&.member?
      Order.where(statistic_profile_id: @user.statistic_profile.id, state: 'cart')
           .where('(SELECT COUNT(*) FROM order_items WHERE order_items.order_id = orders.id) = 0')
           .destroy_all
    end
    if @user&.privileged?
      Order.where(operator_profile_id: @user.invoicing_profile.id, state: 'cart')
           .where('(SELECT COUNT(*) FROM order_items WHERE order_items.order_id = orders.id) = 0')
           .destroy_all
    end
  end
end
