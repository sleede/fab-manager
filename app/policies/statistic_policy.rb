class StatisticPolicy < ApplicationPolicy
  ['index', 'account', 'event', 'machine', 'project', 'subscription', 'training', 'user'].each do |action|
    define_method "#{action}?" do
      user.is_admin?
    end
  end
end
