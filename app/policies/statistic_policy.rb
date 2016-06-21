class StatisticPolicy < ApplicationPolicy
  %w(index account event machine project subscription training user scroll).each do |action|
    define_method "#{action}?" do
      user.is_admin?
    end
  end
end
