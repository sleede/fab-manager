# frozen_string_literal: true

require 'test_helper'

class HistoryValueTest < ActiveSupport::TestCase
  test 'an HistoryValue must be chained with a valid footprint' do
    s = Setting.first
    u = User.admins.first
    hv = HistoryValue.new(setting: s, invoicing_profile: u.invoicing_profile, value: '1, 2, testing ...')
    hv.save!
    assert hv.check_footprint
  end
end
