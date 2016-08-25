class PriceCategoryPolicy < ApplicationPolicy
  %w(show create update destroy).each do |action|
    define_method "#{action}?" do
      user.is_admin?
    end
  end
end
