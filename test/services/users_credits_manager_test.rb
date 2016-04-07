require 'test_helper'

class UsersCreditsManagerTest < ActiveSupport::TestCase
  setup do
    @machine = Machine.find(6)
    @training = Training.find(2)
    @plan = Plan.find(3)
    @user = User.joins(:subscriptions).find_by(subscriptions: { plan: @plan })
    @user.users_credits.destroy_all
    @availability = @machine.availabilities.first
    @reservation_machine = Reservation.new(user: @user, reservable: @machine)
    @reservation_training = Reservation.new(user: @user, reservable: @training)
  end

  ## context machine reservation
  test "machine reservation from user without subscribed plan" do
    @user.subscriptions.destroy_all

    @reservation_machine.assign_attributes(slots_attributes: [{
      start_at: @availability.start_at, end_at: @availability.start_at + 1.hour, availability_id: @availability.id
    }])
    manager = UsersCredits::Manager.new(reservation: @reservation_machine)

    assert_equal false, manager.will_use_credits?
    assert_equal 0, manager.free_hours_count

    assert_no_difference 'UsersCredit.count' do
      manager.update_credits
    end
  end

  test "machine reservation without credit associated" do
    Credit.where(creditable: @machine).destroy_all

    @reservation_machine.assign_attributes(slots_attributes: [{
      start_at: @availability.start_at, end_at: @availability.start_at + 1.hour, availability_id: @availability.id
    }])
    manager = UsersCredits::Manager.new(reservation: @reservation_machine)

    assert_equal false, manager.will_use_credits?
    assert_equal 0, manager.free_hours_count

    assert_no_difference 'UsersCredit.count' do
      manager.update_credits
    end

    assert_raise UsersCredits::AlreadyUpdatedError do
      manager.update_credits
    end
  end

  test "machine reservation with credit associated and user never used his credit" do
    credit = Credit.find_by!(creditable: @machine, plan: @plan)
    credit.update!(hours: 2)
    @user.users_credits.destroy_all

    @reservation_machine.assign_attributes(slots_attributes: [{
      start_at: @availability.start_at, end_at: @availability.start_at + 1.hour, availability_id: @availability.id
    }])
    manager = UsersCredits::Manager.new(reservation: @reservation_machine)

    assert_equal true, manager.will_use_credits?
    assert_equal 1, manager.free_hours_count

    assert_difference 'UsersCredit.count' do
      manager.update_credits
    end

    assert_raise UsersCredits::AlreadyUpdatedError do
      manager.update_credits
    end
  end

  test "machine reservation with credit associated and user already used partially his credit" do
    credit = Credit.find_by!(creditable: @machine, plan: @plan)
    credit.update!(hours: 2)
    users_credit = @user.users_credits.create!(credit: credit, hours_used: 1)

    @reservation_machine.assign_attributes(slots_attributes: [
      { start_at: @availability.start_at, end_at: @availability.start_at + 1.hour, availability_id: @availability.id },
      { start_at: @availability.start_at + 1.hour, end_at: @availability.start_at + 2.hour, availability_id: @availability.id }
    ])

    manager = UsersCredits::Manager.new(reservation: @reservation_machine)

    assert_equal true, manager.will_use_credits?
    assert_equal 1, manager.free_hours_count

    assert_no_difference 'UsersCredit.count' do
      manager.update_credits
    end

    users_credit.reload
    assert_equal 2, users_credit.hours_used
  end

  test "machine reservation with credit associated and user already used all credit" do
    credit = Credit.find_by!(creditable: @machine, plan: @plan)
    users_credit = @user.users_credits.create!(credit: credit, hours_used: 1)

    @reservation_machine.assign_attributes(slots_attributes: [
      { start_at: @availability.start_at, end_at: @availability.start_at + 1.hour, availability_id: @availability.id },
      { start_at: @availability.start_at + 1.hour, end_at: @availability.start_at + 2.hour, availability_id: @availability.id }
    ])
    manager = UsersCredits::Manager.new(reservation: @reservation_machine)

    assert_equal false, manager.will_use_credits?
    assert_equal 0, manager.free_hours_count

    assert_no_difference 'UsersCredit.count' do
      manager.update_credits
    end

    users_credit.reload
    assert_equal 1, users_credit.hours_used
  end

  # context training reservation

  test "training reservation from user without subscribed plan" do
    @user.subscriptions.destroy_all

    manager = UsersCredits::Manager.new(reservation: @reservation_training)

    assert_equal false, manager.will_use_credits?

    assert_no_difference 'UsersCredit.count' do
      manager.update_credits
    end
  end

  test "training reservation without credit associated" do
    Credit.where(creditable: @training).destroy_all

    manager = UsersCredits::Manager.new(reservation: @reservation_training)

    assert_equal false, manager.will_use_credits?

    assert_no_difference 'UsersCredit.count' do
      manager.update_credits
    end

    assert_raise UsersCredits::AlreadyUpdatedError do
      manager.update_credits
    end
  end

  test "training reservation with credit associated and user didnt use his credit yet" do
    credit = Credit.find_or_create_by!(creditable: @training, plan: @plan)
    @user.users_credits.destroy_all

    manager = UsersCredits::Manager.new(reservation: @reservation_training)

    assert_equal true, manager.will_use_credits?

    assert_difference 'UsersCredit.count' do
      manager.update_credits
    end
  end

  test "training reservation with credit associated but user already used all his credits" do
    @user.users_credits.destroy_all
    another_training = Training.where.not(id: @training.id).first
    credit = Credit.find_or_create_by!(creditable: another_training, plan: @plan)
    @user.users_credits.find_or_create_by!(credit: credit)
    @plan.update(training_credit_nb: 1)

    manager = UsersCredits::Manager.new(reservation: @reservation_training)

    assert_equal false, manager.will_use_credits?

    assert_no_difference 'UsersCredit.count' do
      manager.update_credits
    end
  end

  # context reset user credits

  test "use UsersCredit::Manager to reset users_credits" do
    credit = Credit.find_by!(creditable: @machine, plan: @plan)
    users_credit = @user.users_credits.create!(credit: credit, hours_used: 1)

    assert_not_empty @user.users_credits

    manager = UsersCredits::Manager.new(user: @user)
    manager.reset_credits

    assert_empty @user.users_credits.reload
  end
end
