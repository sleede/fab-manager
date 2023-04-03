# frozen_string_literal: true

require 'test_helper'

class ChainedElementTest < ActiveSupport::TestCase
  test 'create a first element' do
    source = Invoice.first
    element = ChainedElement.create!(
      element: source,
      previous: nil
    )
    assert element.persisted?
    assert_not_nil element.content
    assert_not_nil element.footprint
    assert_nil element.previous

    assert element.content.is_a?(Hash)
    FootprintService.footprint_columns(Invoice).each do |col|
      if source[col].blank?
        assert_not_includes element.content.keys, col
      else
        assert_includes element.content.keys, col
      end
    end
    assert_includes element.content.keys, 'previous'

    assert_equal source.id, element.content['id']
    assert_equal source.total, element.content['total']
    assert_equal source.reference, element.content['reference']
    assert_equal source.payment_method, element.content['payment_method']
    assert_nil element.content['previous']
    assert_not element.corrupted?
  end

  test 'chain two elements' do
    source1 = sample_reservation_invoice(users(:user2), users(:user1))
    element1 = source1.chained_element
    assert element1.persisted?
    assert source1.check_footprint

    source2 = sample_reservation_invoice(users(:user3), users(:user1))
    element2 = source2.chained_element
    assert element2.persisted?
    assert element2.content.is_a?(Hash)
    assert_equal element1.footprint, element2.content['previous']
    assert_equal element1.id, element2.previous_id

    assert_not element1.corrupted?
    assert_not element2.corrupted?
    assert source2.check_footprint
  end

  test 'chain element with children embedded json' do
    source = sample_schedule(users(:user2), users(:user1))
    previous = nil
    source.payment_schedule_items.each do |item|
      element = item.chained_element

      assert element.persisted?
      assert_not_nil element.content
      assert_not_nil element.footprint
      assert_equal previous, element.previous unless previous.nil?

      assert element.content.is_a?(Hash)
      FootprintService.footprint_columns(PaymentScheduleItem).each do |col|
        if item[col].blank?
          assert_not_includes element.content.keys, col
        else
          assert_includes element.content.keys, col
          assert item.chained_element.content[col].is_a?(Hash) if item[col].is_a?(Hash)
        end
      end
      assert_includes element.content.keys, 'previous'

      assert_equal item.id, element.content['id']
      assert_equal item.details, element.content['details']
      assert_equal item.payment_schedule_id, element.content['payment_schedule_id']
      assert_not_nil element.content['previous'] unless previous.nil?
      assert_not element.corrupted?

      previous = element
    end
    assert source.check_footprint
  end
end
