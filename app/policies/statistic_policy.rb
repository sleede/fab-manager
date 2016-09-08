class StatisticPolicy < ApplicationPolicy
  %w(index account event machine project subscription training user scroll export_subscription export_machine
     export_training export_event export_account export_project export_global).each do |action|
    define_method "#{action}?" do
      user.is_admin?
    end
  end
end
