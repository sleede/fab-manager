class AvailabilityPolicy < ApplicationPolicy
  %w(index? show? create? update? destroy? reservations?).each do |action|
    define_method action do
      user.is_admin?
    end
  end
end
