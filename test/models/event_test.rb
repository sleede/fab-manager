require 'test_helper'

class EventTest < ActiveSupport::TestCase
  test 'event must have a category' do
    e = Event.first
    assert_not_nil e.category
  end

  test 'event must have a theme' do
    e = Event.find(1)
    assert_not_empty e.themes
  end

  test 'event must have an age range' do
    e = Event.find(2)
    assert_not_nil e.age_range.name
  end

  test 'event must not have any age range' do
    e = Event.find(3)
    assert_nil e.age_range
  end
end
