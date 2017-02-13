require 'test_helper'

class SpaceTest < ActiveSupport::TestCase
  test 'create a space' do
    space = Space.create!({name: 'Bio-lab', description: 'An biological laboratory to experiment bio-technologies', default_places: 5})
    assert_not_nil space
    subtype = StatisticSubType.find_by(key: space.slug)
    assert_not_nil subtype
  end

  test 'update a space' do
    new_name = 'Bio-tech lab'
    space = Space.create!({name: 'Bio-lab', description: 'An biological laboratory to experiment bio-technologies', default_places: 5})
    space.update_attributes({name: new_name})
    subtype = StatisticSubType.find_by(key: space.slug)
    assert_equal new_name, subtype.label
  end

  test 'delete a space' do
    space = Space.create!({name: 'Bio-lab', description: 'An biological laboratory to experiment bio-technologies', default_places: 5})
    slug = space.slug
    space.destroy!
    assert_nil Space.find_by(slug: slug)
    assert_nil StatisticSubType.find_by(key: slug)
  end
end
