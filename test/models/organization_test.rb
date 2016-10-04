require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  test 'organization must have a name' do
    a = Address.new({address: '14 avenue du Maréchal Tartanpion, 12345 Saint-Robert-sur-Mer'})
    o = Organization.new({address: a})
    assert o.invalid?
  end

  test 'organization must have an address' do
    o = Organization.new({name: 'Menuiserie G. Dubois'})
    assert o.invalid?
  end
end
