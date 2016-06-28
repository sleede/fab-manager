class CategoryPolicy < ApplicationPolicy
  %w(index create update destroy show).each do |action|
    define_method "#{action}?" do
      user.is_admin?
    end
  end
end
