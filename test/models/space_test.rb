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

  test "space can be associated with spaces in a tree-like structure" do
    space_1 = Space.create!(name: "space 1", default_places: 2)
    space_1_1 = Space.create!(name: "space 1_1", default_places: 2, parent: space_1)
    space_1_2 = Space.create!(name: "space 1_2", default_places: 2, parent: space_1)
    space_1_2_1 = Space.create!(name: "space 1_2_1", default_places: 2, parent: space_1_2)
    space_other = Space.create!(name: "space other", default_places: 2)

    assert_equal [space_1_1, space_1_2], space_1.children
    assert_equal [], space_1_1.children
    assert_equal [space_1_2_1], space_1_2.children

    assert_equal [space_1, space_1_2], space_1_2_1.ancestors
    assert_equal [space_1], space_1_2.ancestors
    assert_equal [space_1], space_1_1.ancestors
    assert_equal [], space_1.ancestors

    assert_equal [space_1_1, space_1_2, space_1_2_1], space_1.descendants
    assert_equal [], space_1_1.descendants
    assert_equal [space_1_2_1], space_1_2.descendants
    assert_equal [], space_1_2_1.descendants

    assert_equal [], space_other.descendants
    assert_equal [], space_other.ancestors
  end

  test "space can be associated with machines" do
    space = spaces(:space_1)
    machine_1 = machines(:machine_1)
    machine_2 = machines(:machine_2)

    space.machines << machine_1
    space.machines << machine_2

    assert_equal 2, space.machines.count

    assert_equal space, machine_1.space
    assert_equal space, machine_2.space
  end
end
