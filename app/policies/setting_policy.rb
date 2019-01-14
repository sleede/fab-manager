class SettingPolicy < ApplicationPolicy
  %w(update).each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end
end
