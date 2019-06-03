# frozen_string_literal: true

require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  test 'an organization with name and address is valid' do
    a = Address.new(address: '14 avenue du Maréchal Tartanpion, 12345 Saint-Robert-sur-Mer')
    o = Organization.new(name: 'Menuiserie G. Dubois', address: a)
    assert o.valid?
  end

  test 'organization must have a name' do
    a = Address.new(address: '14 avenue du Maréchal Tartanpion, 12345 Saint-Robert-sur-Mer')
    o = Organization.new(address: a)
    assert o.invalid?
  end

  test 'organization must have an address' do
    o = Organization.new(name: 'Menuiserie G. Dubois')
    assert o.invalid?
  end
end
