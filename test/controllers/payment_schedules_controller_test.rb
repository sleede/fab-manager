# frozen_string_literal: true

require 'test_helper'

class PaymentSchedulesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.friendly.find('pjproudhon')
    login_as(@user, scope: :user)
  end

  test "should get user's schedules" do
    get payment_schedules_url
    assert_response :success

    assert_equal @user.invoicing_profile.payment_schedules.count, json_response(response.body).length
  end
end
