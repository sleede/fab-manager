# frozen_string_literal: true

# Check the access policies for API::StatisticsController
class StatisticPolicy < ApplicationPolicy
  %w[index account event machine project subscription training user space order scroll export_subscription export_machine
     export_training export_event export_account export_project export_space export_order export_global].each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end
end
