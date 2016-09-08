require 'test_helper'

class EventPriceCategoryTest < ActiveSupport::TestCase
  test "event price's category cannot be empty" do
    epc = EventPriceCategory.new({price_category_id: 1, event_id: 3})
    assert epc.invalid?
    assert epc.errors[:amount].present?
  end
end
