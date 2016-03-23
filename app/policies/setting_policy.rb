class SettingPolicy < ApplicationPolicy
  %w(update).each do |action|
    define_method "#{action}?" do
      user.is_admin?
    end
  end
end
