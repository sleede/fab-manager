# frozen_string_literal: true

require 'test_helper'

class ReservationContextTest < ActiveSupport::TestCase
  test 'fixtures are valid' do
    ReservationContext.find_each do |reservation_context|
      assert reservation_context.valid?
    end
  end

  test "applicable_on validation" do
    reservation_context = reservation_contexts(:reservation_context_1)

    reservation_context.applicable_on << "wrong"

    assert reservation_context.invalid?
    assert_equal reservation_context.errors.details, { applicable_on: [{ error: :invalid }] }
  end

  test "name validation" do
    reservation_context = reservation_contexts(:reservation_context_1)

    reservation_context.name = nil

    assert reservation_context.invalid?
    assert_equal reservation_context.errors.details, { name: [{ error: :blank }] }
  end

  test "#safe_destroy" do
    reservation_context = reservation_contexts(:reservation_context_1)
    reservation = reservations(:reservation_1).tap { |r| r.update!(reservation_context: reservation_context) }

    assert_not reservation_context.safe_destroy

    reservation.update!(reservation_context_id: nil)

    assert reservation_context.safe_destroy
    assert reservation_context.destroyed?
  end

  test "scope applicable_on" do
    assert_equal reservation_contexts(:reservation_context_1, :reservation_context_2), ReservationContext.applicable_on("space")

    reservation_context = reservation_contexts(:reservation_context_1)
    reservation_context.applicable_on.delete("space")
    reservation_context.save!

    assert_equal [reservation_contexts(:reservation_context_2)], ReservationContext.applicable_on("space")
  end

  test "foreign key on reservations" do
    reservation_context = reservation_contexts(:reservation_context_1)
    reservation = reservations(:reservation_1).tap { |r| r.update!(reservation_context: reservation_context) }

    assert_raise ActiveRecord::InvalidForeignKey do
      reservation_context.destroy!
    end
  end
end
