require 'test_helper'

class TicketTest < ActiveSupport::TestCase
  test "ticket must have at least 1 seat" do
    t = Ticket.new({event_price_category_id: 1, booked: -1})
    assert t.invalid?
    assert t.errors[:booked].present?
  end
end
