class CouponPolicy < ApplicationPolicy
  %w(index show create update destroy send_to).each do |action|
    define_method "#{action}?" do
      user.is_admin?
    end
  end
end
