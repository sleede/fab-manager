class AvailabilityPolicy < ApplicationPolicy
  %w(index? show? create? update? destroy? reservations? export?).each do |action|
    define_method action do
      user.is_admin?
    end
  end
end
