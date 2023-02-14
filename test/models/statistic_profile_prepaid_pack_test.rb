# frozen_string_literal: true

require 'test_helper'

class StatisticProfilePrepaidPackTest < ActiveSupport::TestCase
  test 'coupon have a expries date' do
    prepaid_pack = PrepaidPack.first
    user = User.find_by(username: 'jdupond')
    p = StatisticProfilePrepaidPack.create!(prepaid_pack: prepaid_pack, statistic_profile: user.statistic_profile)
    expires_at = 12.months.from_now
    assert p.expires_at.strftime('%Y-%m-%d'), expires_at.strftime('%Y-%m-%d')
  end
end
