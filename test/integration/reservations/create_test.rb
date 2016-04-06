module Reservations
  class CreateTest < ActionDispatch::IntegrationTest
    setup do
      @user_without_subscription = User.with_role(:member).without_subscription.first
      @user_with_subscription = User.with_role(:member).with_subscription.second
    end

    test "user without subscription reserves a machine with success" do
      login_as(@user_without_subscription, scope: :user)

      machine = Machine.find(6)
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      users_credit_count = UsersCredit.count

      VCR.use_cassette("reservations_create_for_machine_without_subscription_success") do
        post reservations_path, { reservation: {
            user_id: @user_without_subscription.id,
            reservable_id: machine.id,
            reservable_type: machine.class.name,
            card_token: stripe_card_token,
            slots_attributes: [
              { start_at: availability.start_at.to_s(:iso8601),
                end_at: (availability.start_at + 1.hour).to_s(:iso8601),
                availability_id: availability.id
              }
            ]
          }}.to_json, default_headers
      end

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 1, InvoiceItem.count
      assert_equal users_credit_count, UsersCredit.count

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      refute reservation.stp_invoice_id.blank?
      assert_equal 1, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      refute invoice.stp_invoice_id.blank?
      refute invoice.total.blank?

      # invoice_items assertions
      invoice_item = InvoiceItem.last

      assert invoice_item.stp_invoice_item_id
      assert_equal invoice_item.amount, machine.prices.find_by(group_id: @user_without_subscription.group_id).amount
    end

    test "user without subscription reserves a machine with error" do
      login_as(@user_without_subscription, scope: :user)

      machine = Machine.find(6)
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count

      VCR.use_cassette("reservations_create_for_machine_without_subscription_error") do
        post reservations_path, { reservation: {
            user_id: @user_without_subscription.id,
            reservable_id: machine.id,
            reservable_type: machine.class.name,
            card_token: stripe_card_token(error: :card_declined),
            slots_attributes: [
              { start_at: availability.start_at.to_s(:iso8601),
                end_at: (availability.start_at + 1.hour).to_s(:iso8601),
                availability_id: availability.id
              }
            ]
          }}.to_json, default_headers
      end

      # general assertions
      assert_equal 422, response.status
      assert_equal reservations_count, Reservation.count
      assert_equal invoice_count, Invoice.count
      assert_equal invoice_items_count, InvoiceItem.count
    end

    test "user without subscription reserves a training with success" do
      login_as(@user_without_subscription, scope: :user)

      training = Training.first
      availability = training.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count

      VCR.use_cassette("reservations_create_for_training_without_subscription_success") do
        post reservations_path, { reservation: {
            user_id: @user_without_subscription.id,
            reservable_id: training.id,
            reservable_type: training.class.name,
            card_token: stripe_card_token,
            slots_attributes: [
              { start_at: availability.start_at.to_s(:iso8601),
                end_at: (availability.start_at + 1.hour).to_s(:iso8601),
                availability_id: availability.id
              }
            ]
          }}.to_json, default_headers
      end

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 1, InvoiceItem.count

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      refute reservation.stp_invoice_id.blank?
      assert_equal 1, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      refute invoice.stp_invoice_id.blank?
      refute invoice.total.blank?
      # invoice_items
      invoice_item = InvoiceItem.last

      assert invoice_item.stp_invoice_item_id
      assert_equal invoice_item.amount, training.amount_by_group(@user_without_subscription.group_id).amount
    end

    test "user with subscription reserves a machine with success" do
      login_as(@user_with_subscription, scope: :user)

      plan = @user_with_subscription.subscribed_plan
      machine = Machine.find(6)
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_count = Invoice.count
      invoice_items_count = InvoiceItem.count
      users_credit_count = UsersCredit.count

      VCR.use_cassette("reservations_create_for_machine_with_subscription_success") do
        post reservations_path, { reservation: {
            user_id: @user_with_subscription.id,
            reservable_id: machine.id,
            reservable_type: machine.class.name,
            card_token: stripe_card_token,
            slots_attributes: [
              { start_at: availability.start_at.to_s(:iso8601),
                end_at: (availability.start_at + 1.hour).to_s(:iso8601),
                availability_id: availability.id
              },
              { start_at: (availability.start_at + 1.hour).to_s(:iso8601),
                end_at: (availability.start_at + 2.hours).to_s(:iso8601),
                availability_id: availability.id
              }
            ]
          }}.to_json, default_headers
      end

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_count + 1, Invoice.count
      assert_equal invoice_items_count + 2, InvoiceItem.count
      assert_equal users_credit_count + 1, UsersCredit.count

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      refute reservation.stp_invoice_id.blank?
      assert_equal 2, reservation.invoice.invoice_items.count

      # invoice assertions
      invoice = reservation.invoice

      refute invoice.stp_invoice_id.blank?
      refute invoice.total.blank?

      # invoice_items assertions
      invoice_items = InvoiceItem.last(2)
      machine_price = machine.prices.find_by(group_id: @user_with_subscription.group_id, plan_id: plan.id).amount

      assert invoice_items.any? { |invoice| invoice.amount == 0 }
      assert invoice_items.any? { |invoice| invoice.amount == machine_price }
      assert invoice_items.all? { |invoice| invoice.stp_invoice_item_id }

      # users_credits assertions
      users_credit = UsersCredit.last

      assert_equal @user_with_subscription, users_credit.user
      assert_equal [reservation.slots.count, plan.machine_credits.find_by(creditable_id: machine.id).hours].min, users_credit.hours_used
    end
  end
end
