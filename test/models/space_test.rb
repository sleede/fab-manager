# frozen_string_literal: true

require 'test_helper'

class SpaceTest < ActiveSupport::TestCase
  bio_lab = {
    name: 'Bio-lab',
    description: 'An biological laboratory to experiment bio-technologies',
    default_places: 5
  }

  test 'create a space' do
    space = Space.create!(bio_lab)
    assert_not_nil space
    subtype = StatisticSubType.find_by(key: space.slug)
    assert_not_nil subtype
  end

  test 'update a space' do
    new_name = 'Bio-tech lab'
    space = Space.create!(bio_lab)
    space.update(name: new_name)
    subtype = StatisticSubType.find_by(key: space.slug)
    assert_equal new_name, subtype.label
  end

  test 'delete a space' do
    space = Space.create!(bio_lab)
    slug = space.slug
    space.destroy!
    assert_nil Space.find_by(slug: slug)
    assert_nil StatisticSubType.find_by(key: slug)
  end
end
