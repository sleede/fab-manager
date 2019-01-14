class EventThemePolicy < ApplicationPolicy
  %w(create update destroy show).each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end
end
