module Reservations
  class CreateTest < ActionDispatch::IntegrationTest
    setup do
      @user = User.with_role(:member).first
      login_as(@user, scope: :user)
    end

    test "user without plan reserves a machine with success" do
      machine = Machine.find(6)
      availability = machine.availabilities.first

      reservations_count = Reservation.count
      invoice_items_count = InvoiceItem.count

      VCR.use_cassette("reservations_create_without_plan_success") do
        token = Stripe::Token.create(
          :card => {
            :number => "4242424242424242",
            :exp_month => 4,
            :exp_year => 1.year.from_now.year,
            :cvc => "314"
          },
        )

        post reservations_path, { reservation: {
            user_id: @user.id,
            reservable_id: machine.id,
            reservable_type: machine.class.name,
            card_token: token.id,
            slots_attributes: [
              { start_at: availability.start_at.to_s(:iso8601),
                end_at: (availability.start_at + 1.hour).to_s(:iso8601),
                availability_id: availability.id
              }
            ]
          }}.to_json, { 'Accept' => Mime::JSON, 'Content-Type' => Mime::JSON.to_s }
      end

      # general assertions
      assert_equal 201, response.status
      assert_equal reservations_count + 1, Reservation.count
      assert_equal invoice_items_count + 1, InvoiceItem.count

      # reservation assertions
      reservation = Reservation.last

      assert reservation.invoice
      assert_equal 1, reservation.invoice.invoice_items.count

      # invoice_items
      invoice_item = InvoiceItem.last

      assert invoice_item.stp_invoice_item_id
      assert_equal invoice_item.amount, machine.prices.find_by(group_id: @user.group_id).amount


      p json_response(response.body)
    end
  end
end
