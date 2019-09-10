module Reservations
  class CreateTest < ActionDispatch::IntegrationTest
    setup do
      @user_without_subscription = User.with_role(:member).without_subscription.first
      @user_with_subscription = User.with_role(:member).with_subscription.second
    end

    test 'user without subscription reserves a machine with success' do
      login_as(@user_without_subscription, scope: :user)

      machine = Machine.find(6)
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      users_credit_count = UsersCredit.count
      subscriptions_count = Subscription.count

      VCR.use_cassette('reservations_create_for_machine_without_subscription_success') do
        post reservations_path, { reservation: {
          user_id: @user_without_subscription.id,
          reservable_id: machine.id,
          reservable_type: machine.class.name,
          card_token: stripe_card_token,
          slots_attributes: [
            {
              start_at: availability.start_at.to_s(:iso8601),
              end_at: (availability.start_at + 1.hour).to_s(:iso8601),
              availability_id: availability.id
            }
          ]
        } }.to_json, default_headers
      end

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 1, InvoiceItem.count
      assert_equal users_credit_count, UsersCredit.count
      assert_equal subscriptions_count, Subscription.count

      # subscription assertions
      assert_equal 0, @user_without_subscription.subscriptions.count
      assert_nil @user_without_subscription.subscribed_plan

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      assert_equal 1, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      refute invoice.stp_payment_intent_id.blank?
      refute invoice.total.blank?
      assert invoice.check_footprint

      # invoice_items assertions
      invoice_item = InvoiceItem.last

      assert_equal invoice_item.amount, machine.prices.find_by(group_id: @user_without_subscription.group_id, plan_id: nil).amount
      assert invoice_item.check_footprint

      # invoice assertions
      invoice = Invoice.find_by(invoiced: reservation)
      assert_invoice_pdf invoice

      # notification
      assert_not_empty Notification.where(attached_object: reservation)
    end

    test 'user without subscription reserves a machine with error' do
      login_as(@user_without_subscription, scope: :user)

      machine = Machine.find(6)
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      notifications_count = Notification.count

      VCR.use_cassette('reservations_create_for_machine_without_subscription_error') do
        post reservations_path, { reservation: {
          user_id: @user_without_subscription.id,
          reservable_id: machine.id,
          reservable_type: machine.class.name,
          card_token: stripe_card_token(error: :card_declined),
          slots_attributes: [
            {
              start_at: availability.start_at.to_s(:iso8601),
              end_at: (availability.start_at + 1.hour).to_s(:iso8601),
              availability_id: availability.id
            }
          ]
        } }.to_json, default_headers
      end

      # general assertions
      assert_equal 422, response.status
      assert_equal reservations_count, Reservation.count
      assert_equal invoice_count, Invoice.count
      assert_equal invoice_items_count, InvoiceItem.count
      assert_equal notifications_count, Notification.count

      # subscription assertions
      assert_equal 0, @user_without_subscription.subscriptions.count
      assert_nil @user_without_subscription.subscribed_plan
    end

    test 'user without subscription reserves a training with success' do
      login_as(@user_without_subscription, scope: :user)

      training = Training.first
      availability = training.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count

      VCR.use_cassette('reservations_create_for_training_without_subscription_success') do
        post reservations_path, { reservation: {
          user_id: @user_without_subscription.id,
          reservable_id: training.id,
          reservable_type: training.class.name,
          card_token: stripe_card_token,
          slots_attributes: [
            {
              start_at: availability.start_at.to_s(:iso8601),
              end_at: availability.end_at.to_s(:iso8601),
              availability_id: availability.id
            }
          ]
        } }.to_json, default_headers
      end

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 1, InvoiceItem.count

      # subscription assertions
      assert_equal 0, @user_without_subscription.subscriptions.count
      assert_nil @user_without_subscription.subscribed_plan

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      assert_equal 1, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      refute invoice.stp_payment_intent_id.blank?
      refute invoice.total.blank?
      assert invoice.check_footprint

      # invoice_items
      invoice_item = InvoiceItem.last

      assert_equal invoice_item.amount, training.amount_by_group(@user_without_subscription.group_id).amount
      assert invoice_item.check_footprint

      # invoice assertions
      invoice = Invoice.find_by(invoiced: reservation)
      assert_invoice_pdf invoice

      # notification
      assert_not_empty Notification.where(attached_object: reservation)
    end

    test 'user with subscription reserves a machine with success' do
      login_as(@user_with_subscription, scope: :user)

      plan = @user_with_subscription.subscribed_plan
      machine = Machine.find(6)
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      users_credit_count = UsersCredit.count

      VCR.use_cassette('reservations_create_for_machine_with_subscription_success') do
        post reservations_path, { reservation: {
          user_id: @user_with_subscription.id,
          reservable_id: machine.id,
          reservable_type: machine.class.name,
          card_token: stripe_card_token,
          slots_attributes: [
            {
              start_at: availability.start_at.to_s(:iso8601),
              end_at: (availability.start_at + 1.hour).to_s(:iso8601),
              availability_id: availability.id
            },
            {
              start_at: (availability.start_at + 1.hour).to_s(:iso8601),
              end_at: (availability.start_at + 2.hours).to_s(:iso8601),
              availability_id: availability.id
            }
          ]
        } }.to_json, default_headers
      end

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 2, InvoiceItem.count
      assert_equal users_credit_count + 1, UsersCredit.count

      # subscription assertions
      assert_equal 1, @user_with_subscription.subscriptions.count
      assert_not_nil @user_with_subscription.subscribed_plan
      assert_equal plan.id, @user_with_subscription.subscribed_plan.id

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      assert_equal 2, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      refute invoice.stp_payment_intent_id.blank?
      refute invoice.total.blank?
      assert invoice.check_footprint

      # invoice_items assertions
      invoice_items = InvoiceItem.last(2)
      machine_price = machine.prices.find_by(group_id: @user_with_subscription.group_id, plan_id: plan.id).amount

      assert(invoice_items.any? { |inv| inv.amount.zero? })
      assert(invoice_items.any? { |inv| inv.amount == machine_price })
      assert(invoice_items.all?(&:check_footprint))

      # users_credits assertions
      users_credit = UsersCredit.last

      assert_equal @user_with_subscription, users_credit.user
      assert_equal [reservation.slots.count, plan.machine_credits.find_by(creditable_id: machine.id).hours].min, users_credit.hours_used

      # invoice assertions
      invoice = Invoice.find_by(invoiced: reservation)
      assert_invoice_pdf invoice

      # notification
      assert_not_empty Notification.where(attached_object: reservation)
    end

    test 'user with subscription reserves the FIRST training with success' do
      login_as(@user_with_subscription, scope: :user)
      plan = @user_with_subscription.subscribed_plan
      plan.update!(is_rolling: true)

      training = Training.joins(credits: :plan).where(credits: { plan: plan }).first
      availability = training.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count

      VCR.use_cassette('reservations_create_for_training_with_subscription_success') do
        post reservations_path, { reservation: {
          user_id: @user_with_subscription.id,
          reservable_id: training.id,
          reservable_type: training.class.name,
          card_token: stripe_card_token,
          slots_attributes: [
            {
              start_at: availability.start_at.to_s(:iso8601),
              end_at: availability.end_at.to_s(:iso8601),
              availability_id: availability.id
            }
          ]
        } }.to_json, default_headers
      end

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 1, InvoiceItem.count

      # subscription assertions
      assert_equal 1, @user_with_subscription.subscriptions.count
      assert_not_nil @user_with_subscription.subscribed_plan
      assert_equal plan.id, @user_with_subscription.subscribed_plan.id

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      assert_equal 1, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      refute invoice.stp_payment_intent_id.blank?
      refute invoice.total.blank?
      assert invoice.check_footprint

      # invoice_items
      invoice_item = InvoiceItem.last

      assert_equal 0, invoice_item.amount # amount is 0 because this training is a credited training with that plan
      assert invoice_item.check_footprint

      # invoice assertions
      invoice = Invoice.find_by(invoiced: reservation)
      assert_invoice_pdf invoice

      # notification
      assert_not_empty Notification.where(attached_object: reservation)

      # check that user subscription were extended
      assert_equal reservation.slots.first.start_at + plan.duration, @user_with_subscription.subscription.expired_at
    end

    test 'user reserves a machine and pay by wallet with success' do
      @vlonchamp = User.find_by(username: 'vlonchamp')
      login_as(@vlonchamp, scope: :user)

      machine = Machine.find(6)
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      users_credit_count = UsersCredit.count
      wallet_transactions_count = WalletTransaction.count

      VCR.use_cassette('reservations_create_for_machine_and_pay_wallet_success') do
        post reservations_path, { reservation: {
          user_id: @vlonchamp.id,
          reservable_id: machine.id,
          reservable_type: machine.class.name,
          card_token: stripe_card_token,
          slots_attributes: [
            {
              start_at: availability.start_at.to_s(:iso8601),
              end_at: (availability.start_at + 1.hour).to_s(:iso8601),
              availability_id: availability.id
            }
          ]
        } }.to_json, default_headers
      end

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 1, InvoiceItem.count
      assert_equal users_credit_count, UsersCredit.count
      assert_equal wallet_transactions_count + 1, WalletTransaction.count

      # subscription assertions
      assert_equal 0, @vlonchamp.subscriptions.count
      assert_nil @vlonchamp.subscribed_plan

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      assert_equal 1, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      refute invoice.stp_payment_intent_id.blank?
      refute invoice.total.blank?
      assert invoice.check_footprint

      # invoice_items assertions
      invoice_item = InvoiceItem.last

      assert_equal invoice_item.amount, machine.prices.find_by(group_id: @vlonchamp.group_id, plan_id: nil).amount
      assert invoice_item.check_footprint

      # invoice assertions
      invoice = Invoice.find_by(invoiced: reservation)
      assert_invoice_pdf invoice

      # notification
      assert_not_empty Notification.where(attached_object: reservation)

      # wallet
      assert_equal @vlonchamp.wallet.amount, 0
      assert_equal @vlonchamp.wallet.wallet_transactions.count, 2
      transaction = @vlonchamp.wallet.wallet_transactions.last
      assert_equal transaction.transaction_type, 'debit'
      assert_equal transaction.amount, 10
      assert_equal transaction.amount, invoice.wallet_amount / 100.0
    end

    test 'user reserves a training and a subscription by wallet with success' do
      @vlonchamp = User.find_by(username: 'vlonchamp')
      login_as(@vlonchamp, scope: :user)

      training = Training.first
      availability = training.availabilities.first
      plan = Plan.find_by(group_id: @vlonchamp.group.id, type: 'Plan', base_name: 'Mensuel tarif réduit')

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      wallet_transactions_count = WalletTransaction.count

      VCR.use_cassette('reservations_create_for_training_and_plan_by_pay_wallet_success') do
        post reservations_path, { reservation: {
          user_id: @user_without_subscription.id,
          reservable_id: training.id,
          reservable_type: training.class.name,
          card_token: stripe_card_token,
          plan_id: plan.id,
          slots_attributes: [
            {
              start_at: availability.start_at.to_s(:iso8601),
              end_at: availability.end_at.to_s(:iso8601),
              availability_id: availability.id
            }
          ]
        } }.to_json, default_headers
      end

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 2, InvoiceItem.count
      assert_equal wallet_transactions_count + 1, WalletTransaction.count

      # subscription assertions
      assert_equal 1, @vlonchamp.subscriptions.count
      assert_not_nil @vlonchamp.subscribed_plan
      assert_equal plan.id, @vlonchamp.subscribed_plan.id

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      assert_equal 2, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      refute invoice.stp_payment_intent_id.blank?
      refute invoice.total.blank?
      assert_equal invoice.total, 2000
      assert invoice.check_footprint

      # invoice assertions
      invoice = Invoice.find_by(invoiced: reservation)
      assert_invoice_pdf invoice

      # notification
      assert_not_empty Notification.where(attached_object: reservation)

      # wallet
      assert_equal @vlonchamp.wallet.amount, 0
      assert_equal @vlonchamp.wallet.wallet_transactions.count, 2
      transaction = @vlonchamp.wallet.wallet_transactions.last
      assert_equal transaction.transaction_type, 'debit'
      assert_equal transaction.amount, 10
      assert_equal transaction.amount, invoice.wallet_amount / 100.0
    end

    test 'user reserves a machine and a subscription using a coupon with success' do
      login_as(@user_without_subscription, scope: :user)

      machine = Machine.find(6)
      plan = Plan.where(group_id: @user_without_subscription.group_id).first
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      subscriptions_count = Subscription.count
      users_credit_count = UsersCredit.count

      VCR.use_cassette('reservations_machine_and_plan_using_coupon_success') do
        post reservations_path, {
          reservation: {
            user_id: @user_without_subscription.id,
            reservable_id: machine.id,
            reservable_type: machine.class.name,
            card_token: stripe_card_token,
            slots_attributes: [
              {
                start_at: availability.start_at.to_s(:iso8601),
                end_at: (availability.start_at + 1.hour).to_s(:iso8601),
                availability_id: availability.id
              }
            ],
            plan_id: plan.id
          },
          coupon_code: 'SUNNYFABLAB'
        }.to_json, default_headers
      end

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 2, InvoiceItem.count
      assert_equal users_credit_count, UsersCredit.count
      assert_equal subscriptions_count + 1, Subscription.count

      # subscription assertions
      assert_equal 1, @user_without_subscription.subscriptions.count
      assert_not_nil @user_without_subscription.subscribed_plan
      assert_equal plan.id, @user_without_subscription.subscribed_plan.id

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      assert_equal 2, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      refute invoice.stp_payment_intent_id.blank?
      refute invoice.total.blank?
      assert invoice.check_footprint

      # invoice_items assertions
      ## reservation
      reservation_item = invoice.invoice_items.where(subscription_id: nil).first

      assert_not_nil reservation_item
      assert_equal reservation_item.amount, machine.prices.find_by(group_id: @user_without_subscription.group_id, plan_id: plan.id).amount
      assert reservation_item.check_footprint
      ## subscription
      subscription_item = invoice.invoice_items.where.not(subscription_id: nil).first

      assert_not_nil subscription_item

      subscription = Subscription.find(subscription_item.subscription_id)

      assert_equal subscription_item.amount, plan.amount
      assert_equal subscription.plan_id, plan.id
      assert subscription_item.check_footprint

      # invoice assertions
      invoice = Invoice.find_by(invoiced: reservation)
      assert_invoice_pdf invoice

      VCR.use_cassette('reservations_machine_and_plan_using_coupon_retrieve_invoice_from_stripe') do
        stp_intent = Stripe::PaymentIntent.retrieve(invoice.stp_payment_intent_id)
        assert_equal stp_intent.amount, invoice.total
      end

      # notifications
      assert_not_empty Notification.where(attached_object: reservation)
      assert_not_empty Notification.where(attached_object: subscription)
    end

    test 'user reserves a training with an expired coupon with error' do
      login_as(@user_without_subscription, scope: :user)

      training = Training.find(1)
      availability = training.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      notifications_count = Notification.count

      VCR.use_cassette('reservations_training_with_expired_coupon_error') do
        post reservations_path, {
          reservation: {
            user_id: @user_without_subscription.id,
            reservable_id: training.id,
            reservable_type: training.class.name,
            card_token: stripe_card_token,
            slots_attributes: [
              {
                start_at: availability.start_at.to_s(:iso8601),
                end_at: (availability.start_at + 1.hour).to_s(:iso8601),
                availability_id: availability.id
              }
            ]
          },
          coupon_code: 'XMAS10'
        }.to_json, default_headers
      end

      # general assertions
      assert_equal 422, response.status
      assert_equal reservations_count, Reservation.count
      assert_equal invoice_count, Invoice.count
      assert_equal invoice_items_count, InvoiceItem.count
      assert_equal notifications_count, Notification.count

      # subscription assertions
      assert_equal 0, @user_without_subscription.subscriptions.count
      assert_nil @user_without_subscription.subscribed_plan
    end
  end
end
