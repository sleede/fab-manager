# frozen_string_literal: true

# Check the access policies for API::ExportsController
class ExportPolicy < ApplicationPolicy
  %w[export_reservations export_members export_subscriptions export_availabilities download status].each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end
end
