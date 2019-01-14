class AvailabilityPolicy < ApplicationPolicy
  %w(index? show? create? update? destroy? reservations? export? lock?).each do |action|
    define_method action do
      user.admin?
    end
  end
end
