class ReservationContextPolicy < ApplicationPolicy
  %w(create update destroy applicable_on_values).each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end
end
