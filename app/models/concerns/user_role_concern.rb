# frozen_string_literal: true

# Add role-based functionalities to the user model
module UserRoleConcern
  extend ActiveSupport::Concern

  included do
    def admin?
      has_role? :admin
    end

    def member?
      has_role? :member
    end

    def manager?
      has_role? :manager
    end

    def partner?
      has_role? :partner
    end

    def privileged?
      admin? || manager?
    end

    def role
      if admin?
        'admin'
      elsif manager?
        'manager'
      elsif member?
        'member'
      else
        'other'
      end
    end
  end

  class_methods do
    def admins
      User.with_role(:admin)
    end

    def members
      User.with_role(:member)
    end

    def partners
      User.with_role(:partner)
    end

    def managers
      User.with_role(:manager)
    end

    def admins_and_managers
      User.with_any_role(:admin, :manager)
    end

    def online_payers
      User.with_any_role(:admin, :manager, :member)
    end

    def adminsys
      return if Rails.application.secrets.adminsys_email.blank?

      User.find_by('lower(email) = ?', Rails.application.secrets.adminsys_email&.downcase)
    end
  end
end
