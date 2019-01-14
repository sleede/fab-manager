module Reservations
  class CreateAsAdminTest < ActionDispatch::IntegrationTest
    setup do
      @user_without_subscription = User.with_role(:member).without_subscription.first
      @user_with_subscription = User.with_role(:member).with_subscription.second
      @admin = User.with_role(:admin).first
      login_as(@admin, scope: :user)
    end

    test 'user without subscription reserves a machine with success' do
      machine = Machine.find(6)
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      users_credit_count = UsersCredit.count

      post reservations_path, { reservation: {
        user_id: @user_without_subscription.id,
        reservable_id: machine.id,
        reservable_type: machine.class.name,
        slots_attributes: [
          {
            start_at: availability.start_at.to_s(:iso8601),
            end_at: (availability.start_at + 1.hour).to_s(:iso8601),
            availability_id: availability.id
          }
        ]
      } }.to_json, default_headers

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 1, InvoiceItem.count
      assert_equal users_credit_count, UsersCredit.count

      # subscription assertions
      assert_equal 0, @user_without_subscription.subscriptions.count
      assert_nil @user_without_subscription.subscribed_plan

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      assert reservation.stp_invoice_id.blank?
      assert_equal 1, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      assert invoice.stp_invoice_id.blank?
      refute invoice.total.blank?

      # invoice_items assertions
      invoice_item = InvoiceItem.last

      refute invoice_item.stp_invoice_item_id
      assert_equal invoice_item.amount, machine.prices.find_by(group_id: @user_without_subscription.group_id, plan_id: nil).amount

      # invoice assertions
      invoice = Invoice.find_by(invoiced: reservation)
      assert_invoice_pdf invoice

      # notification
      assert_not_empty Notification.where(attached_object: reservation)
    end

    test 'user without subscription reserves a training with success' do
      training = Training.first
      availability = training.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count

      post reservations_path, { reservation: {
        user_id: @user_without_subscription.id,
        reservable_id: training.id,
        reservable_type: training.class.name,
        slots_attributes: [
          {
            start_at: availability.start_at.to_s(:iso8601),
            end_at: (availability.start_at + 1.hour).to_s(:iso8601),
            availability_id: availability.id
          }
        ]
      } }.to_json, default_headers

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
      assert reservation.stp_invoice_id.blank?
      assert_equal 1, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      assert invoice.stp_invoice_id.blank?
      refute invoice.total.blank?
      # invoice_items
      invoice_item = InvoiceItem.last

      refute invoice_item.stp_invoice_item_id
      assert_equal invoice_item.amount, training.amount_by_group(@user_without_subscription.group_id).amount

      # invoice assertions
      invoice = Invoice.find_by(invoiced: reservation)
      assert_invoice_pdf invoice

      # notification
      assert_not_empty Notification.where(attached_object: reservation)
    end

    test 'user with subscription reserves a machine with success' do
      plan = @user_with_subscription.subscribed_plan
      machine = Machine.find(6)
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      users_credit_count = UsersCredit.count

      post reservations_path, { reservation: {
        user_id: @user_with_subscription.id,
        reservable_id: machine.id,
        reservable_type: machine.class.name,
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
      assert reservation.stp_invoice_id.blank?
      assert_equal 2, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      assert invoice.stp_invoice_id.blank?
      refute invoice.total.blank?

      # invoice_items assertions
      invoice_items = InvoiceItem.last(2)
      machine_price = machine.prices.find_by(group_id: @user_with_subscription.group_id, plan_id: plan.id).amount

      assert(invoice_items.any? { |ii| ii.amount.zero? })
      assert(invoice_items.any? { |ii| ii.amount == machine_price })
      assert(invoice_items.all? { |ii| ii.stp_invoice_item_id.blank? })

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

    test 'user without subscription reserves a machine and pay by wallet with success' do
      @vlonchamp = User.find_by(username: 'vlonchamp')
      machine = Machine.find(6)
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      users_credit_count = UsersCredit.count

      post reservations_path, { reservation: {
        user_id: @vlonchamp.id,
        reservable_id: machine.id,
        reservable_type: machine.class.name,
        slots_attributes: [
          {
            start_at: availability.start_at.to_s(:iso8601),
            end_at: (availability.start_at + 1.hour).to_s(:iso8601),
            availability_id: availability.id
          }
        ]
      } }.to_json, default_headers

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 1, InvoiceItem.count
      assert_equal users_credit_count, UsersCredit.count

      # subscription assertions
      assert_equal 0, @user_without_subscription.subscriptions.count
      assert_nil @user_without_subscription.subscribed_plan

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      assert reservation.stp_invoice_id.blank?
      assert_equal 1, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      assert invoice.stp_invoice_id.blank?
      refute invoice.total.blank?

      # invoice_items assertions
      invoice_item = InvoiceItem.last

      refute invoice_item.stp_invoice_item_id
      assert_equal invoice_item.amount, machine.prices.find_by(group_id: @vlonchamp.group_id, plan_id: nil).amount

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
      assert_equal transaction.id, invoice.wallet_transaction_id
    end

    test 'user reserves a machine and a subscription pay by wallet with success' do
      @vlonchamp = User.find_by(username: 'vlonchamp')
      machine = Machine.find(6)
      availability = machine.availabilities.first
      plan = Plan.find_by(group_id: @vlonchamp.group.id, type: 'Plan', base_name: 'Mensuel tarif réduit')

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      users_credit_count = UsersCredit.count
      wallet_transactions_count = WalletTransaction.count

      post reservations_path, { reservation: {
        user_id: @vlonchamp.id,
        reservable_id: machine.id,
        reservable_type: machine.class.name,
        plan_id: plan.id,
        slots_attributes: [
          {
            start_at: availability.start_at.to_s(:iso8601),
            end_at: (availability.start_at + 1.hour).to_s(:iso8601),
            availability_id: availability.id
          }
        ]
      } }.to_json, default_headers

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 2, InvoiceItem.count
      assert_equal users_credit_count + 1, UsersCredit.count
      assert_equal wallet_transactions_count + 1, WalletTransaction.count

      # subscription assertions
      assert_equal 1, @vlonchamp.subscriptions.count
      assert_not_nil @vlonchamp.subscribed_plan
      assert_equal plan.id, @vlonchamp.subscribed_plan.id

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      assert reservation.stp_invoice_id.blank?
      assert_equal 2, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      assert invoice.stp_invoice_id.blank?
      refute invoice.total.blank?
      assert_equal invoice.total, 2000

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
      assert_equal transaction.id, invoice.wallet_transaction_id
    end

    test 'user without subscription reserves a machine and pay wallet with success' do
      @vlonchamp = User.find_by(username: 'vlonchamp')
      machine = Machine.find(6)
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      users_credit_count = UsersCredit.count

      post reservations_path, { reservation: {
        user_id: @vlonchamp.id,
        reservable_id: machine.id,
        reservable_type: machine.class.name,
        slots_attributes: [
          {
            start_at: availability.start_at.to_s(:iso8601),
            end_at: (availability.start_at + 1.hour).to_s(:iso8601),
            availability_id: availability.id
          }
        ]
      } }.to_json, default_headers

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 1, InvoiceItem.count
      assert_equal users_credit_count, UsersCredit.count

      # subscription assertions
      assert_equal 0, @vlonchamp.subscriptions.count
      assert_nil @vlonchamp.subscribed_plan

      # reservation assertions
      reservation = Reservation.last

      assert_not_nil reservation.invoice
      assert reservation.stp_invoice_id.blank?

      # notification
      assert_not_empty Notification.where(attached_object: reservation)
    end

    test 'user reserves a training and a subscription with success' do
      training = Training.first
      availability = training.availabilities.first
      plan = Plan.where(group_id: @user_without_subscription.group.id, type: 'Plan').first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      users_credit_count = UsersCredit.count

      post reservations_path, { reservation: {
        user_id: @user_without_subscription.id,
        plan_id: plan.id,
        reservable_id: training.id,
        reservable_type: training.class.name,
        slots_attributes: [
          {
            start_at: availability.start_at.to_s(:iso8601),
            end_at: (availability.start_at + 1.hour).to_s(:iso8601),
            offered: false,
            availability_id: availability.id
          }
        ]
      } }.to_json, default_headers

      # general assertions
      assert_equal 201, response.status
      assert_equal Mime::JSON, response.content_type
      result = json_response(response.body)

      # Check the DB objects have been created as they should
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 2, InvoiceItem.count
      assert_equal users_credit_count + 1, UsersCredit.count

      # subscription assertions
      assert_equal 1, @user_without_subscription.subscriptions.count
      assert_not_nil @user_without_subscription.subscribed_plan
      assert_equal plan.id, @user_without_subscription.subscribed_plan.id

      # reservation assertions
      reservation = Reservation.find(result[:id])

      assert reservation.invoice
      assert reservation.stp_invoice_id.blank?
      assert_equal 2, reservation.invoice.invoice_items.count

      # credits assertions
      assert_equal 1, @user_without_subscription.credits.count
      assert_equal 'Training', @user_without_subscription.credits.last.creditable_type
      assert_equal training.id, @user_without_subscription.credits.last.creditable_id

      # invoice assertions
      invoice = reservation.invoice

      assert invoice.stp_invoice_id.blank?
      refute invoice.total.blank?
      assert_equal plan.amount, invoice.total

      # invoice_items
      invoice_items = InvoiceItem.last(2)

      assert(invoice_items.all? { |ii| ii.stp_invoice_item_id.blank? })
      assert(invoice_items.any? { |ii| ii.amount == plan.amount && !ii.subscription_id.nil? })
      assert(invoice_items.any? { |ii| ii.amount.zero? })

      # invoice assertions
      invoice = Invoice.find_by(invoiced: reservation)
      assert_invoice_pdf invoice

      # notification
      assert_not_empty Notification.where(attached_object: reservation)
    end
  end
end
